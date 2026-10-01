CREATE TABLE "AiDailyUsage" (
  "dayUTC" DATE NOT NULL,
  scope VARCHAR(64) NOT NULL,
  count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
  PRIMARY KEY ("dayUTC", scope)
);
CREATE TABLE "AiQuotaReservation" (
  id UUID PRIMARY KEY,
  "userId" UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  "dayUTC" DATE NOT NULL,
  "releasedAt" TIMESTAMPTZ(3),
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "AiQuotaReservation_userId_dayUTC_idx" ON "AiQuotaReservation"("userId", "dayUTC");
