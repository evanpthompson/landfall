BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "remote_display_settings" (
    "id" bigserial PRIMARY KEY,
    "displayId" text NOT NULL,
    "dimEnabled" boolean NOT NULL DEFAULT true,
    "dimStartHour" bigint NOT NULL DEFAULT 22,
    "dimEndHour" bigint NOT NULL DEFAULT 7,
    "dimLevel" double precision NOT NULL DEFAULT 0.85,
    "locationName" text NOT NULL DEFAULT ''::text,
    "photoSourceJson" text,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "remote_display_settings_display_id_idx" ON "remote_display_settings" USING btree ("displayId");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260607190957002', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260607190957002', "timestamp" = now();

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
