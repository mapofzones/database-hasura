
ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_peers";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out_percent";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in_percent";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_mainnet_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_mainnet_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_mainnet_rating";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_rating";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow";
