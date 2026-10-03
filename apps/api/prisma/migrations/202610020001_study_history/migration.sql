ALTER TABLE "StudyGoal" ADD COLUMN "contextKey" VARCHAR(40), ADD COLUMN "dailyTarget" INTEGER NOT NULL DEFAULT 10;
ALTER TABLE "StudyGoal" ADD CONSTRAINT "StudyGoal_contextKey_check" CHECK ("contextKey" IS NULL OR "contextKey" IN ('freeStudy','bb2026')),
  ADD CONSTRAINT "StudyGoal_dailyTarget_check" CHECK ("dailyTarget" IN (5,10,20));
CREATE UNIQUE INDEX "StudyGoal_userId_contextKey_key" ON "StudyGoal" ("userId","contextKey");
CREATE TABLE "StudyAnswer" (
  id UUID PRIMARY KEY,
  "userId" UUID NOT NULL,
  "goalId" UUID NOT NULL,
  "topicId" VARCHAR(100) NOT NULL,
  "contentVersion" INTEGER NOT NULL CHECK ("contentVersion">0),
  "questionId" VARCHAR(100) NOT NULL,
  "optionIndex" INTEGER NOT NULL CHECK ("optionIndex" BETWEEN 0 AND 3),
  source VARCHAR(8) NOT NULL CHECK (source IN ('quiz','review')),
  correct BOOLEAN NOT NULL,
  "receivedAt" TIMESTAMPTZ(3) NOT NULL,
  ordinal BIGSERIAL NOT NULL UNIQUE,
  FOREIGN KEY ("userId","goalId") REFERENCES "StudyGoal" ("userId",id) ON DELETE CASCADE
);
CREATE INDEX "StudyAnswer_context_date_idx" ON "StudyAnswer" ("userId","goalId","receivedAt");
CREATE INDEX "StudyAnswer_context_topic_idx" ON "StudyAnswer" ("userId","goalId","topicId","contentVersion");
CREATE TABLE "StudyQuestionError" (
  "userId" UUID NOT NULL,
  "goalId" UUID NOT NULL,
  "topicId" VARCHAR(100) NOT NULL,
  "contentVersion" INTEGER NOT NULL CHECK ("contentVersion">0),
  "questionId" VARCHAR(100) NOT NULL,
  "wrongCount" INTEGER NOT NULL CHECK ("wrongCount">0),
  "firstWrongAt" TIMESTAMPTZ(3) NOT NULL,
  "lastWrongAt" TIMESTAMPTZ(3) NOT NULL,
  "lastAnswerAt" TIMESTAMPTZ(3) NOT NULL,
  "lastOptionIndex" INTEGER NOT NULL CHECK ("lastOptionIndex" BETWEEN 0 AND 3),
  status VARCHAR(8) NOT NULL CHECK (status IN ('pending','reviewed')),
  PRIMARY KEY ("userId","goalId","topicId","contentVersion","questionId"),
  FOREIGN KEY ("userId","goalId") REFERENCES "StudyGoal" ("userId",id) ON DELETE CASCADE
);
CREATE INDEX "StudyQuestionError_context_status_date_idx" ON "StudyQuestionError" ("userId","goalId",status,"lastWrongAt" DESC,"topicId","contentVersion","questionId");
