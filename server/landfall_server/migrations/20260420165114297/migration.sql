BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "landfall_otp_accounts" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "authUserId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "landfall_otp_accounts_email_idx" ON "landfall_otp_accounts" USING btree ("email");
CREATE INDEX "landfall_otp_accounts_auth_user_id_idx" ON "landfall_otp_accounts" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "landfall_otp_requests" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "codeHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "landfall_otp_requests_email_idx" ON "landfall_otp_requests" USING btree ("email");
CREATE INDEX "landfall_otp_requests_expires_at_idx" ON "landfall_otp_requests" USING btree ("expiresAt");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260420165114297', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260420165114297', "timestamp" = now();

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
