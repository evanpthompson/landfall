BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "photos" (
    "id" bigserial PRIMARY KEY,
    "credentialId" bigint NOT NULL,
    "providerFileId" text NOT NULL,
    "filename" text NOT NULL,
    "mimeType" text NOT NULL,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "photos_credential_idx" ON "photos" USING btree ("credentialId");
CREATE UNIQUE INDEX "photos_provider_file_id_uniq" ON "photos" USING btree ("providerFileId");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260425002710188', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260425002710188', "timestamp" = now();

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
