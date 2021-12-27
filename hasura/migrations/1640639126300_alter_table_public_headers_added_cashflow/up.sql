
ALTER TABLE "public"."headers" ADD COLUMN "ibc_cashflow_period" bigint NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "ibc_cashflow_period_diff" bigint NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "top_ibc_cashflow_zone_pair" jsonb NULL;
