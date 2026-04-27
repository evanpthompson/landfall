BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "integration_packs" (
    "id" bigserial PRIMARY KEY,
    "packId" text NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "version" text NOT NULL,
    "priceUsd" double precision NOT NULL,
    "authorName" text NOT NULL,
    "iconUrl" text,
    "stripePaymentLink" text,
    "isActive" boolean NOT NULL DEFAULT true
);

-- Indexes
CREATE UNIQUE INDEX "integration_packs_pack_id_idx" ON "integration_packs" USING btree ("packId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "license_keys" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "tier" text NOT NULL,
    "activatedByUserId" text,
    "activatedAt" timestamp without time zone,
    "purchasedAt" timestamp without time zone NOT NULL,
    "stripeSessionId" text,
    "buyerEmail" text
);

-- Indexes
CREATE UNIQUE INDEX "license_keys_key_idx" ON "license_keys" USING btree ("key");
CREATE INDEX "license_keys_user_idx" ON "license_keys" USING btree ("activatedByUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "owned_packs" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "packId" text NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL,
    "stripeSessionId" text
);

-- Indexes
CREATE UNIQUE INDEX "owned_packs_user_pack_idx" ON "owned_packs" USING btree ("userId", "packId");
CREATE INDEX "owned_packs_user_idx" ON "owned_packs" USING btree ("userId");


--
-- SEED: Initial integration pack catalog
--
INSERT INTO "integration_packs" ("packId", "name", "description", "version", "priceUsd", "authorName", "isActive")
VALUES
  ('sports_scores', 'Sports Scores', 'Live game scores and ticker updates for NFL, NBA, MLB, NHL, and soccer leagues.', '1.0.0', 5.0, 'Landfall', true),
  ('home_assistant', 'Home Assistant', 'Deep Home Assistant integration — sensor cards, device control actions, alert cards for automations.', '1.0.0', 7.0, 'Landfall', true),
  ('todoist', 'Todoist & Google Tasks', 'Your task lists on the display. Shows due today, overdue, and upcoming tasks from Todoist or Google Tasks.', '1.0.0', 5.0, 'Landfall', true),
  ('rss_headlines', 'RSS Headlines', 'Rotating news headlines from any RSS feed. Configurable sources, refresh interval, and max items.', '1.0.0', 5.0, 'Landfall', true),
  ('countdown_timers', 'Countdown Timers', 'Countdown cards to any date — vacations, birthdays, project deadlines. Multiple timers shown in rotation.', '1.0.0', 5.0, 'Landfall', true),
  ('stocks_crypto', 'Stocks & Crypto', 'Live price cards for stocks, ETFs, and crypto. Configurable symbols, price alerts, sparkline history.', '1.0.0', 8.0, 'Landfall', true)
ON CONFLICT ("packId") DO NOTHING;

--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260427035322536', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260427035322536', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
