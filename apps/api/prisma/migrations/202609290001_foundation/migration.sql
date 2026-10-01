CREATE TABLE "User" (
  "id" UUID PRIMARY KEY,
  "externalId" VARCHAR(128) NOT NULL UNIQUE,
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE "StudyGoal" (
  "id" UUID PRIMARY KEY,
  "userId" UUID NOT NULL REFERENCES "User"("id") ON DELETE CASCADE,
  "name" VARCHAR(120) NOT NULL CHECK (length(trim("name")) > 0),
  "category" VARCHAR(40) NOT NULL CHECK (length(trim("category")) > 0),
  "examDate" DATE,
  "timezone" VARCHAR(80) NOT NULL DEFAULT 'America/Sao_Paulo',
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ(3) NOT NULL,
  UNIQUE ("userId", "id")
);
CREATE INDEX "StudyGoal_userId_createdAt_id_idx" ON "StudyGoal" ("userId", "createdAt", "id");
