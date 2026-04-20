BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "weather_current" (
    "id" bigserial PRIMARY KEY,
    "locationName" text NOT NULL,
    "tempC" double precision NOT NULL,
    "feelsLikeC" double precision NOT NULL,
    "condition" text NOT NULL,
    "iconCode" text NOT NULL,
    "humidity" bigint NOT NULL,
    "windSpeedMs" double precision NOT NULL,
    "fetchedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "weather_forecasts" (
    "id" bigserial PRIMARY KEY,
    "locationName" text NOT NULL,
    "forecastDate" timestamp without time zone NOT NULL,
    "minTempC" double precision NOT NULL,
    "maxTempC" double precision NOT NULL,
    "condition" text NOT NULL,
    "iconCode" text NOT NULL,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "weather_forecasts_date_idx" ON "weather_forecasts" USING btree ("forecastDate");


--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260420040001206', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260420040001206', "timestamp" = now();

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
