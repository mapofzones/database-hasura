
ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_pending_mainnet" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_in_mainnet_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "ibc_cashflow_out_mainnet_diff" bigint NULL DEFAULT 0;
