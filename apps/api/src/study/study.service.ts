import {BadRequestException,NotFoundException} from '@nestjs/common';
import {Prisma} from '@prisma/client';
import {randomUUID} from 'node:crypto';
import {StudyDirectory,LearningEntry} from '../catalog/study-directory';
import {SqlExecutor} from '../goals/goal.repository';
import {SqlTransactionProvider} from '../database/transaction';
import {HistoryConflict,HistoryContentChanged} from '../errors';
import {StudyScope,StudyGoalContext,StudyAnswerInput,ConfirmedAnswer,GoalRow,AnswerRow} from './study.models';
import {goalQuery,ensureQuery,answerQuery,insertAnswer,updateError} from './study.queries';
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function identity(...ids:string[]){if(ids.some(id=>!uuid.test(id)))throw new BadRequestException();}
function context(goal:GoalRow):StudyGoalContext{
  if(goal.contextKey!=='freeStudy'&&goal.contextKey!=='bb2026')throw new NotFoundException();
  return {id:goal.id,scope:goal.contextKey,timezone:goal.timezone,dailyTarget:goal.dailyTarget};
}
function confirmation(row:AnswerRow):ConfirmedAnswer{return {answerId:row.id,goalId:row.goalId,topicId:row.topicId,contentVersion:row.contentVersion,questionId:row.questionId,optionIndex:row.optionIndex,source:row.source,correct:row.correct,receivedAt:row.receivedAt.toISOString()};}
export class StudyHistoryService {
  constructor(private readonly database:SqlExecutor & SqlTransactionProvider,private readonly directory:StudyDirectory,private readonly clock:()=>Date=()=>new Date()){}
  private async goal(tx:SqlExecutor,userId:string,goalId:string,lock=false){
    identity(userId,goalId);
    const goal=(await tx.query<GoalRow>(goalQuery(userId,goalId,lock)))[0];
    if(!goal)throw new NotFoundException();
    context(goal);return goal;
  }
  async ensureContext(userId:string,scope:StudyScope):Promise<StudyGoalContext>{
    identity(userId);if(scope!=='freeStudy'&&scope!=='bb2026')throw new BadRequestException();
    return this.database.transaction(async tx=>{
      await tx.query(ensureQuery(randomUUID(),userId,scope));
      const rows=await tx.query<GoalRow>(Prisma.sql`SELECT id,"userId","contextKey",timezone,"dailyTarget" FROM "StudyGoal" WHERE "userId"=${userId}::uuid AND "contextKey"=${scope}`);
      return context(rows[0]!);
    });
  }
  async setDailyTarget(userId:string,goalId:string,target:5|10|20):Promise<StudyGoalContext>{
    if(![5,10,20].includes(target))throw new BadRequestException();
    return this.database.transaction(async tx=>{
      const goal=await this.goal(tx,userId,goalId,true);
      await tx.query(Prisma.sql`UPDATE "StudyGoal" SET "dailyTarget"=${target},"updatedAt"=CURRENT_TIMESTAMP WHERE "userId"=${userId}::uuid AND id=${goalId}::uuid`);
      return {...context(goal),dailyTarget:target};
    });
  }
  private entry(scope:StudyScope,input:StudyAnswerInput):LearningEntry{
    if(!Number.isInteger(input.optionIndex)||input.optionIndex<0||input.optionIndex>3||!Number.isInteger(input.contentVersion)||input.contentVersion<1||!['quiz','review'].includes(input.source))throw new BadRequestException();
    const entry=this.directory.find(input.topicId);
    if(!entry||(scope==='freeStudy'?entry.area!=='freeStudy':entry.courseId!=='bb2026'))throw new BadRequestException();
    if(entry.contentVersion!==input.contentVersion)throw new HistoryContentChanged();
    if(!entry.topic.questions.some(q=>q.id===input.questionId))throw new BadRequestException();
    return entry;
  }
  async confirmAnswer(userId:string,goalId:string,answerId:string,input:StudyAnswerInput):Promise<ConfirmedAnswer>{
    identity(userId,goalId,answerId);
    return this.database.transaction(async tx=>{
      const goal=await this.goal(tx,userId,goalId,true);
      const previous=(await tx.query<AnswerRow>(answerQuery(answerId)))[0];
      if(previous){
        if(previous.userId!==userId||previous.goalId!==goalId||(['topicId','contentVersion','questionId','optionIndex','source'] as const).some(k=>previous[k]!==input[k]))throw new HistoryConflict();
        return confirmation(previous);
      }
      const entry=this.entry(goal.contextKey!,input),question=entry.topic.questions.find(q=>q.id===input.questionId)!;
      const now=this.clock(),correct=question.correctIndex===input.optionIndex;
      const row=(await tx.query<AnswerRow>(insertAnswer(answerId,userId,goalId,input,correct,now)))[0];
      if(!row)throw new HistoryConflict();
      await tx.query(updateError(userId,goalId,input,correct,now));
      return confirmation(row);
    });
  }
}
