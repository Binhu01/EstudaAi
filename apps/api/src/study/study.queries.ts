import {Prisma} from '@prisma/client';
import {StudyAnswerInput,StudyScope} from './study.models';
export const goalQuery=(userId:string,goalId:string,lock=false)=>Prisma.sql`SELECT id,"userId","contextKey",timezone,"dailyTarget" FROM "StudyGoal" WHERE "userId"=${userId}::uuid AND id=${goalId}::uuid ${lock?Prisma.sql`FOR UPDATE`:Prisma.empty}`;
export const ensureQuery=(id:string,userId:string,scope:StudyScope)=>Prisma.sql`INSERT INTO "StudyGoal" (id,"userId",name,category,"contextKey","updatedAt") VALUES (${id}::uuid,${userId}::uuid,${scope==='bb2026'?'Banco do Brasil 2026':'Estudo livre'},${scope==='bb2026'?'contest':'school'},${scope},CURRENT_TIMESTAMP) ON CONFLICT ("userId","contextKey") DO NOTHING`;
export const answerQuery=(id:string)=>Prisma.sql`SELECT * FROM "StudyAnswer" WHERE id=${id}::uuid`;
export function insertAnswer(id:string,userId:string,goalId:string,input:StudyAnswerInput,correct:boolean,now:Date){
  return Prisma.sql`INSERT INTO "StudyAnswer" (id,"userId","goalId","topicId","contentVersion","questionId","optionIndex",source,correct,"receivedAt") VALUES (${id}::uuid,${userId}::uuid,${goalId}::uuid,${input.topicId},${input.contentVersion},${input.questionId},${input.optionIndex},${input.source},${correct},${now}) ON CONFLICT (id) DO NOTHING RETURNING *`;
}
export function updateError(userId:string,goalId:string,input:StudyAnswerInput,correct:boolean,now:Date){
  return Prisma.sql`INSERT INTO "StudyQuestionError" ("userId","goalId","topicId","contentVersion","questionId","wrongCount","firstWrongAt","lastWrongAt","lastAnswerAt","lastOptionIndex",status)
  SELECT ${userId}::uuid,${goalId}::uuid,${input.topicId},${input.contentVersion},${input.questionId},1,${now},${now},${now},${input.optionIndex},${correct?'reviewed':'pending'}
  WHERE ${!correct} OR EXISTS (SELECT 1 FROM "StudyQuestionError" WHERE "userId"=${userId}::uuid AND "goalId"=${goalId}::uuid AND "topicId"=${input.topicId} AND "contentVersion"=${input.contentVersion} AND "questionId"=${input.questionId})
  ON CONFLICT ("userId","goalId","topicId","contentVersion","questionId") DO UPDATE SET
  "wrongCount"="StudyQuestionError"."wrongCount"+${correct?0:1}, "lastWrongAt"=CASE WHEN ${correct} THEN "StudyQuestionError"."lastWrongAt" ELSE EXCLUDED."lastWrongAt" END,
  "lastAnswerAt"=EXCLUDED."lastAnswerAt","lastOptionIndex"=EXCLUDED."lastOptionIndex",status=EXCLUDED.status`;
}
