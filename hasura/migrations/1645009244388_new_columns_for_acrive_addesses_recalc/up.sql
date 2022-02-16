
ALTER TABLE "public"."active_addresses" ADD COLUMN "is_internal_tx" boolean NULL;

ALTER TABLE "public"."active_addresses" ADD COLUMN "is_internal_transfer" boolean NULL;

ALTER TABLE "public"."active_addresses" ADD COLUMN "is_external_transfer" boolean NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_rating" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_rating_diff" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_mainnet_rating" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_mainnet_rating_diff" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_mainnet_weight" numeric NULL DEFAULT 0;
