BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "calendar_events" (
    "id" bigserial PRIMARY KEY,
    "credentialId" bigint NOT NULL,
    "calendarId" text NOT NULL,
    "calendarName" text NOT NULL,
    "externalEventId" text NOT NULL,
    "title" text NOT NULL,
    "startTime" timestamp without time zone NOT NULL,
    "endTime" timestamp without time zone NOT NULL,
    "isAllDay" boolean NOT NULL DEFAULT false,
    "location" text,
    "description" text,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "calendar_events_credential_idx" ON "calendar_events" USING btree ("credentialId");
CREATE INDEX "calendar_events_start_time_idx" ON "calendar_events" USING btree ("startTime");
CREATE UNIQUE INDEX "calendar_events_external_id_idx" ON "calendar_events" USING btree ("credentialId", "externalEventId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "calendar_linked_credentials" (
    "id" bigserial PRIMARY KEY,
    "authUserId" uuid NOT NULL,
    "provider" text NOT NULL,
    "providerEmail" text NOT NULL,
    "accessToken" text NOT NULL,
    "refreshToken" text,
    "tokenExpiresAt" timestamp without time zone,
    "scopes" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "calendar_linked_credentials_auth_user_idx" ON "calendar_linked_credentials" USING btree ("authUserId");
CREATE UNIQUE INDEX "calendar_linked_credentials_provider_email_idx" ON "calendar_linked_credentials" USING btree ("provider", "providerEmail");
CREATE INDEX "calendar_linked_credentials_active_idx" ON "calendar_linked_credentials" USING btree ("isActive");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260424230408249', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260424230408249', "timestamp" = now();

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
