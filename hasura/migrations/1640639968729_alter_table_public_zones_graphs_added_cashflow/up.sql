
ALTER TABLE "public"."zones_graphs" ADD COLUMN "source_cashflow_in" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "source_cashflow_in_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "source_cashflow_out" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "source_cashflow_out_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "source_transfers_period" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "target_cashflow_in" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "target_cashflow_in_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "target_cashflow_out" bigint NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "target_cashflow_out_percent" numeric NULL DEFAULT 0;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "target_transfers_period" bigint NULL DEFAULT 0;
