BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "companion_entities" (
    "id" bigserial PRIMARY KEY,
    "displayId" text NOT NULL,
    "seed" bigint NOT NULL,
    "rarityTier" text NOT NULL,
    "speciesId" text NOT NULL,
    "name" text NOT NULL,
    "traits" text NOT NULL,
    "evolutionStage" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "assetCredit" text,
    "lastEvolutionAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "companion_entities_display_id_idx" ON "companion_entities" USING btree ("displayId");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260511181056937', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260511181056937', "timestamp" = now();

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
