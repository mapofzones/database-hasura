
ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_mainnet_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_mainnet_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_mainnet_rating";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_rating";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses";

ALTER TABLE "public"."active_addresses" DROP COLUMN "is_external_transfer";

ALTER TABLE "public"."active_addresses" DROP COLUMN "is_internal_transfer";

ALTER TABLE "public"."active_addresses" DROP COLUMN "is_internal_tx";
