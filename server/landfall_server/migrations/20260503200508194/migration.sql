BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "theme_purchases" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "themeId" bigint NOT NULL,
    "purchasedAt" timestamp without time zone NOT NULL,
    "stripePaymentIntentId" text
);

-- Indexes
CREATE UNIQUE INDEX "theme_purchases_user_theme_idx" ON "theme_purchases" USING btree ("userId", "themeId");
CREATE INDEX "theme_purchases_user_idx" ON "theme_purchases" USING btree ("userId");
CREATE INDEX "theme_purchases_stripe_idx" ON "theme_purchases" USING btree ("stripePaymentIntentId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "themes" ADD COLUMN "isMarketplace" boolean NOT NULL DEFAULT false;
ALTER TABLE "themes" ADD COLUMN "priceUsd" bigint;
ALTER TABLE "themes" ADD COLUMN "stripeProductId" text;
CREATE INDEX "themes_marketplace_idx" ON "themes" USING btree ("isMarketplace");

--
-- MIGRATION VERSION FOR landfall
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('landfall', '20260503200508194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260503200508194', "timestamp" = now();

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
