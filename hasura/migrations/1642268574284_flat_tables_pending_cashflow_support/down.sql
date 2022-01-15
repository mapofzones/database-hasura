
ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_mainnet_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_mainnet_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_mainnet_rating";

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_transfers_weight" TYPE integer;

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_weight";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_rating_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_rating";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_pending";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_transfers";

ALTER TABLE "public"."zones_stats" DROP COLUMN "chart_cashflow";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_out_pending";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_in_pending";

ALTER TABLE "public"."zones_stats" DROP COLUMN "ibc_cashflow_pending";

ALTER TABLE "public"."headers" DROP COLUMN "chart_transfers";

ALTER TABLE "public"."headers" DROP COLUMN "ibc_transfers_pending_period";

ALTER TABLE "public"."headers" DROP COLUMN "ibc_transfers_period_diff";

ALTER TABLE "public"."headers" DROP COLUMN "ibc_transfers_period";

ALTER TABLE "public"."headers" DROP COLUMN "chart_cashflow";

ALTER TABLE "public"."headers" DROP COLUMN "ibc_cashflow_pending_period";

ALTER TABLE "public"."headers" DROP COLUMN "top_transfer_zone_pair";

ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "ibc_cashflow_out_pending";

ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "ibc_cashflow_in_pending";

ALTER TABLE "public"."ft_channels_stats" DROP COLUMN "ibc_cashflow_out_pending";

ALTER TABLE "public"."ft_channels_stats" DROP COLUMN "ibc_cashflow_in_pending";
