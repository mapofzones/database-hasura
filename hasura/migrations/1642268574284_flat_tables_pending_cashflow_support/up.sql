
ALTER TABLE "public"."ft_channels_stats" ADD COLUMN "ibc_cashflow_in_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."ft_channels_stats" ADD COLUMN "ibc_cashflow_out_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "ibc_cashflow_in_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "ibc_cashflow_out_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "top_transfer_zone_pair" jsonb NULL;

ALTER TABLE "public"."headers" ADD COLUMN "ibc_cashflow_pending_period" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "chart_cashflow" jsonb NULL;

ALTER TABLE "public"."headers" ADD COLUMN "ibc_transfers_period" int4 NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "ibc_transfers_period_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "ibc_transfers_pending_period" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "chart_transfers" jsonb NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_pending" bigint NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "chart_cashflow" jsonb NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_pending" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_rating" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_rating_diff" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_weight" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_transfers_weight" TYPE numeric;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_mainnet_rating" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_mainnet_rating_diff" integer NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_mainnet_weight" numeric NOT NULL DEFAULT 0;
