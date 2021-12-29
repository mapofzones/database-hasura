
ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_peers_mainnet" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_mainnet_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_mainnet_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_rating_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_mainnet_rating_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_mainnet_rating" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_mainnet_weight" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_rating_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_mainnet_rating_diff" integer NULL DEFAULT 0;
