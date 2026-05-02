BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "themes" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL,
    "name" text NOT NULL,
    "schemaVersion" text NOT NULL,
    "author" text,
    "description" text,
    "previewUrl" text,
    "tagsJson" text NOT NULL DEFAULT '[]'::text,
    "tokensJson" text NOT NULL,
    "resolvedJson" text NOT NULL,
    "isBuiltIn" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "themes_slug_idx" ON "themes" USING btree ("slug");
CREATE INDEX "themes_builtin_idx" ON "themes" USING btree ("isBuiltIn");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260502035310545', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260502035310545', "timestamp" = now();

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
