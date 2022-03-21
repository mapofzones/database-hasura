

ALTER TABLE "public"."zones_stats" ADD COLUMN "website" varchar NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_mainnet" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_active_addresses_mainnet_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "success_rate_mainnet" numeric NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_mainnet_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_percent_mainnet" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_percent_mainnet" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_mainnet" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_mainnet_diff" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_transfers_pending_mainnet" integer NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_pending_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_pending_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_active_addresses_mainnet" DROP NOT NULL;

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_active_addresses_mainnet_diff" DROP NOT NULL;

