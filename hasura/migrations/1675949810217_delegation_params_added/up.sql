
ALTER TABLE "public"."zone_parameters" ADD COLUMN IF NOT EXISTS "delegation_amount" numeric NULL;

ALTER TABLE "public"."zone_parameters" ADD COLUMN IF NOT EXISTS "undelegation_amount" numeric NULL;

ALTER TABLE "public"."zone_parameters" ADD COLUMN IF NOT EXISTS "delegators_count" integer NULL;
