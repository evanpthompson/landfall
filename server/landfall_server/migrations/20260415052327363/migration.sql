BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "cards" (
    "id" bigserial PRIMARY KEY,
    "externalId" text NOT NULL,
    "source" text NOT NULL,
    "title" text NOT NULL,
    "body" text,
    "dataJson" text,
    "layout" text NOT NULL DEFAULT 'medium'::text,
    "priority" text NOT NULL DEFAULT 'normal'::text,
    "expiresAt" timestamp without time zone,
    "persistent" boolean NOT NULL DEFAULT false,
    "dismissedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "cards_external_id_idx" ON "cards" USING btree ("externalId");
CREATE INDEX "cards_dismissed_at_idx" ON "cards" USING btree ("dismissedAt");
CREATE INDEX "cards_expires_at_idx" ON "cards" USING btree ("expiresAt");
CREATE INDEX "cards_created_at_idx" ON "cards" USING btree ("createdAt");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260415052327363', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260415052327363', "timestamp" = now();

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
