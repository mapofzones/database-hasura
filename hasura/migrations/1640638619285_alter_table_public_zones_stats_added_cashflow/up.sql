
ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_rating_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_mainnet_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_mainnet_rating_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_mainnet_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_peers" integer NULL DEFAULT 0;
