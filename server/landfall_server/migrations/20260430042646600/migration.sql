BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "dashboard_profiles" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "slug" text NOT NULL,
    "isActive" boolean NOT NULL DEFAULT false,
    "themeId" text,
    "cardFilterJson" text NOT NULL DEFAULT '{}'::text,
    "scheduleJson" text,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "columnsCount" bigint NOT NULL DEFAULT 12,
    "rowsCount" bigint NOT NULL DEFAULT 8,
    "cardsJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "dashboard_profiles_slug_idx" ON "dashboard_profiles" USING btree ("slug");
CREATE INDEX "dashboard_profiles_active_idx" ON "dashboard_profiles" USING btree ("isActive");
CREATE INDEX "dashboard_profiles_sort_idx" ON "dashboard_profiles" USING btree ("sortOrder");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260430042646600', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260430042646600', "timestamp" = now();

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
