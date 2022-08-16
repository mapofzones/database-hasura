
ALTER TABLE "public"."nodes_rpc_addrs" ALTER COLUMN "earliest_block_height" TYPE int8;

ALTER TABLE "public"."nodes_rpc_addrs" ALTER COLUMN "last_block_height" TYPE int8;

ALTER TABLE "public"."token_prices" ADD COLUMN "coingecko_symbol_market_cap_in_usd" numeric NULL;

ALTER TABLE "public"."token_prices" ADD COLUMN "coingecko_symbol_total_volumes_in_usd" numeric NULL;

ALTER TABLE "public"."token_prices" ADD COLUMN "symbol_supply" numeric NULL;
