
ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_active_addresses_mainnet_diff" SET NOT NULL;

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_active_addresses_mainnet" SET NOT NULL;

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out_pending_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in_pending_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_pending_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_mainnet_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out_percent_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in_percent_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_mainnet_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "success_rate_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_mainnet_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_active_addresses_mainnet";

ALTER TABLE "public"."zones_stats" DROP COLUMN "website";
