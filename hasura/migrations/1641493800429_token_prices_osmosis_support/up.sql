
ALTER TABLE "public"."tokens" ADD COLUMN "osmosis_id" varchar NULL;

ALTER TABLE "public"."token_prices" ALTER COLUMN "coingecko_symbol_price_in_usd" DROP NOT NULL;

ALTER TABLE "public"."token_prices" ADD COLUMN "osmosis_symbol_price_in_usd" numeric NULL;
