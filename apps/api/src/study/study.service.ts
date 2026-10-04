import {BadRequestException,NotFoundException} from '@nestjs/common';
import {Prisma} from '@prisma/client';
import {randomUUID} from 'node:crypto';
import {StudyDirectory,LearningEntry} from '../catalog/study-directory';
import {SqlExecutor} from '../goals/goal.repository';
import {SqlTransactionProvider} from '../database/transaction';
import {HistoryConflict,HistoryContentChanged} from '../errors';
import {StudyScope,StudyGoalContext,StudyAnswerInput,ConfirmedAnswer,GoalRow,AnswerRow,StudyDashboard,DailyActivity,SubjectStats,ErrorQuery,StudyErrorItem,StudyErrorPage} from './study.models';
import {goalQuery,ensureQuery,answerQuery,insertAnswer,updateError,catalogRows,activeAnswers} from './study.queries';
import {studyDates} from './study.calendar';
import {studyConsistency} from './study.progress';
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
  async readDashboard(userId:string,goalId:string):Promise<StudyDashboard>{
    return this.database.transaction(async tx=>{
      const row=await this.goal(tx,userId,goalId,true),goal=context(row),now=this.clock(),dates=studyDates(now,goal.timezone);
      const catalog=catalogRows(this.directory,goal.scope),answers=Prisma.sql`${activeAnswers(userId,goalId)} AND a."receivedAt"<=${now}`;
      const activityRows=await tx.query<DailyActivity>(Prisma.sql`WITH ${catalog} SELECT (a."receivedAt" AT TIME ZONE ${goal.timezone})::date::text AS date,count(DISTINCT (a."topicId",a."contentVersion",a."questionId"))::int AS "differentQuestions",count(*)::int AS attempts,count(*) FILTER (WHERE a.correct)::int AS correct ${answers} AND a."receivedAt">=${dates[0]!.start} AND a."receivedAt"<${dates[6]!.end} GROUP BY date`);
      const activity=dates.map(d=>activityRows.find(r=>r.date===d.date)??{date:d.date,differentQuestions:0,attempts:0,correct:0});
      const latest=Prisma.sql`latest AS (SELECT DISTINCT ON (a."topicId",a."contentVersion",a."questionId") a."topicId",a."contentVersion",a."questionId",a.correct,c.subject ${answers} ORDER BY a."topicId",a."contentVersion",a."questionId",a.ordinal DESC)`;
      const subjectRows=await tx.query<Omit<SubjectStats,'progress'> & {practicedQuestions:number;latestCorrectQuestions:number}>(Prisma.sql`WITH ${catalog},${latest} SELECT c.subject AS id,c.title,count(*)::int AS attempts,count(*) FILTER (WHERE a.correct)::int AS correct,count(DISTINCT (a."topicId",a."contentVersion",a."questionId"))::int AS "practicedQuestions",(SELECT count(*)::int FROM latest l WHERE l.subject=c.subject AND l.correct) AS "latestCorrectQuestions" ${answers} GROUP BY c.subject,c.title ORDER BY c.title,c.subject`);
      const entries=this.directory.topicIds.map(id=>this.directory.find(id)!).filter(e=>goal.scope==='freeStudy'?e.area==='freeStudy':e.courseId==='bb2026');
      const catalogCounts=new Map<string,number>();
      for(const entry of entries){
        const subject=goal.scope==='freeStudy'?entry.topic.id:entry.disciplineId!;
        catalogCounts.set(subject,(catalogCounts.get(subject)??0)+entry.topic.questions.length);
      }
      const subjects=subjectRows.map(({practicedQuestions,latestCorrectQuestions,...subject})=>({...subject,progress:{practicedQuestions,latestCorrectQuestions,catalogQuestions:catalogCounts.get(subject.id)!}}));
      const counts=(await tx.query<{practicedQuestions:number;correctReviewQuestions:number}>(Prisma.sql`WITH ${catalog} SELECT count(DISTINCT (a."topicId",a."contentVersion",a."questionId"))::int AS "practicedQuestions",count(DISTINCT (a."topicId",a."contentVersion",a."questionId")) FILTER (WHERE a.correct AND a.source='review')::int AS "correctReviewQuestions" ${answers}`))[0]!;
      const reviewedErrors=(await tx.query<{n:number}>(Prisma.sql`WITH ${catalog},${latest} SELECT count(*)::int AS n FROM latest l JOIN "StudyQuestionError" e ON e."topicId"=l."topicId" AND e."contentVersion"=l."contentVersion" AND e."questionId"=l."questionId" WHERE e."userId"=${userId}::uuid AND e."goalId"=${goalId}::uuid AND e."firstWrongAt"<=${now} AND l.correct`))[0]!.n;
      const activeDates=await tx.query<{date:string}>(Prisma.sql`WITH ${catalog} SELECT DISTINCT (a."receivedAt" AT TIME ZONE ${goal.timezone})::date::text AS date ${answers} ORDER BY date`);
      const progress={...counts,catalogQuestions:entries.reduce((n,e)=>n+e.topic.questions.length,0),reviewedErrors,...studyConsistency(activeDates.map(v=>v.date),activity[6]!.date)};
      const resume=(await tx.query<{topicId:string;contentVersion:number}>(Prisma.sql`WITH ${catalog} SELECT a."topicId",a."contentVersion" ${answers} ORDER BY a.ordinal DESC LIMIT 1`))[0]??null;
      const pending=(await tx.query<{n:number}>(Prisma.sql`WITH ${catalog},${latest} SELECT count(*)::int AS n FROM latest l JOIN "StudyQuestionError" e ON e."topicId"=l."topicId" AND e."contentVersion"=l."contentVersion" AND e."questionId"=l."questionId" WHERE e."userId"=${userId}::uuid AND e."goalId"=${goalId}::uuid AND NOT l.correct`))[0]!.n;
      return {goal,today:activity[6]!,pendingErrors:pending,activity,subjects,resume,progress};
    });
  }
  async listErrors(userId:string,goalId:string,query:ErrorQuery):Promise<StudyErrorPage>{
    if(!['pending','reviewed'].includes(query.status)||!Number.isInteger(query.limit)||query.limit<1||query.limit>50)throw new BadRequestException();
    return this.database.transaction(async tx=>{
      const row=await this.goal(tx,userId,goalId,true),scope=context(row).scope;
      const entries=this.directory.topicIds.map(id=>this.directory.find(id)!).filter(e=>scope==='freeStudy'?e.area==='freeStudy':e.courseId==='bb2026');
      if(query.subjectId&&!entries.some(e=>(scope==='freeStudy'?e.topic.id:e.disciplineId)===query.subjectId))throw new BadRequestException();
      let continuation=Prisma.empty;
      if(query.cursor){
        try{
          if(query.cursor.length>4096||!/^[A-Za-z0-9_-]+$/.test(query.cursor))throw Error();
          const c=JSON.parse(Buffer.from(query.cursor,'base64url').toString('utf8'));
          if(c.userId!==userId||c.goalId!==goalId||c.status!==query.status||c.subjectId!==(query.subjectId??null)||typeof c.date!=='string'||new Date(c.date).toISOString()!==c.date||typeof c.topicId!=='string'||!/^[a-z0-9-]{1,100}$/.test(c.topicId)||typeof c.questionId!=='string'||!/^[a-z0-9-]{1,100}$/.test(c.questionId)||!Number.isInteger(c.version)||c.version<1)throw Error();
          continuation=Prisma.sql`AND (e."lastWrongAt",e."topicId",e."contentVersion",e."questionId")<(${new Date(c.date)}::timestamptz,${c.topicId}::text,${c.version}::int,${c.questionId}::text)`;
        }catch{throw new BadRequestException();}
      }
      const rows=await tx.query<Omit<StudyErrorItem,'firstWrongAt'|'lastWrongAt'|'lastAnswerAt'> & {firstWrongAt:Date;lastWrongAt:Date;lastAnswerAt:Date}>(Prisma.sql`WITH ${catalogRows(this.directory,scope)} SELECT e."topicId",e."contentVersion",e."questionId",e."wrongCount",e."firstWrongAt",e."lastWrongAt",e."lastAnswerAt",e."lastOptionIndex",e.status,CASE WHEN c.version=e."contentVersion" AND e."questionId"=ANY(c.questions) THEN 'current' ELSE 'outdated' END AS "contentStatus" FROM "StudyQuestionError" e LEFT JOIN catalog c ON e."topicId"=c."topicId" WHERE e."userId"=${userId}::uuid AND e."goalId"=${goalId}::uuid AND e.status=${query.status} ${query.subjectId?Prisma.sql`AND c.subject=${query.subjectId}`:Prisma.empty} ${continuation} ORDER BY e."lastWrongAt" DESC,e."topicId" DESC,e."contentVersion" DESC,e."questionId" DESC LIMIT ${query.limit+1}`);
      const more=rows.length>query.limit,items=rows.slice(0,query.limit).map(r=>({...r,firstWrongAt:r.firstWrongAt.toISOString(),lastWrongAt:r.lastWrongAt.toISOString(),lastAnswerAt:r.lastAnswerAt.toISOString()})),last=items.at(-1);
      const nextCursor=more&&last?Buffer.from(JSON.stringify({userId,goalId,status:query.status,subjectId:query.subjectId??null,date:last.lastWrongAt,topicId:last.topicId,version:last.contentVersion,questionId:last.questionId})).toString('base64url'):null;
      return {items,nextCursor};
    });
  }
}
