BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "layout_configs" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "presetType" text NOT NULL DEFAULT 'custom'::text,
    "columnsCount" integer NOT NULL DEFAULT 12,
    "rowsCount" integer NOT NULL DEFAULT 8,
    "cardsJson" text NOT NULL,
    "isActive" boolean NOT NULL DEFAULT false,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "layout_configs_preset_idx" ON "layout_configs" USING btree ("presetType");
CREATE INDEX "layout_configs_active_idx" ON "layout_configs" USING btree ("isActive");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260427000000001', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260427000000001', "timestamp" = now();

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
