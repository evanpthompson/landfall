BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "api_keys" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "keyHash" text NOT NULL,
    "prefix" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "lastUsedAt" timestamp without time zone,
    "revokedAt" timestamp without time zone,
    "dailyLimit" bigint NOT NULL DEFAULT 500,
    "usageCount" bigint NOT NULL DEFAULT 0,
    "usageResetAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "api_keys_hash_idx" ON "api_keys" USING btree ("keyHash");
CREATE INDEX "api_keys_revoked_at_idx" ON "api_keys" USING btree ("revokedAt");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260418205249682', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260418205249682', "timestamp" = now();

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
