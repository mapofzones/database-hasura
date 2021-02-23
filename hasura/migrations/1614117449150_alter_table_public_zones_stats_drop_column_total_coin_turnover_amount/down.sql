ALTER TABLE "public"."zones_stats" ADD COLUMN "total_coin_turnover_amount" numeric;
ALTER TABLE "public"."zones_stats" ALTER COLUMN "total_coin_turnover_amount" DROP NOT NULL;
ALTER TABLE "public"."zones_stats" ALTER COLUMN "total_coin_turnover_amount" SET DEFAULT 0;
