
ALTER TABLE "public"."token_prices" DROP COLUMN "symbol_supply";

ALTER TABLE "public"."token_prices" DROP COLUMN "coingecko_symbol_total_volumes_in_usd";

ALTER TABLE "public"."token_prices" DROP COLUMN "coingecko_symbol_market_cap_in_usd";

ALTER TABLE "public"."nodes_rpc_addrs" ALTER COLUMN "last_block_height" TYPE integer;

ALTER TABLE "public"."nodes_rpc_addrs" ALTER COLUMN "earliest_block_height" TYPE integer;
