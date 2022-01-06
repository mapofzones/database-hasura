
ALTER TABLE "public"."token_prices" DROP COLUMN "osmosis_symbol_price_in_usd";

ALTER TABLE "public"."token_prices" ALTER COLUMN "coingecko_symbol_price_in_usd" SET NOT NULL;

ALTER TABLE "public"."tokens" DROP COLUMN "osmosis_id";
