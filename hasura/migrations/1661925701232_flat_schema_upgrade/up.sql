
ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "txs_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_active_addresses_cnt_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_cashflow_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_cashflow_in_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_cashflow_out_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_transfers_weight" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "active_addresses_cnt_rating" integer NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "active_addresses_cnt_rating_diff" integer NULL;

ALTER TABLE "flat"."channels_stats" ADD COLUMN "ibc_cashflow" bigint NULL;

ALTER TABLE "flat"."channels_stats" ADD COLUMN "ibc_cashflow_diff" bigint NULL;

ALTER TABLE "flat"."channels_stats" ADD COLUMN "ibc_cashflow_pending" bigint NULL;

ALTER TABLE "flat"."blockchain_stats" ADD COLUMN "active_addresses_cnt" integer NULL;

ALTER TABLE "flat"."blockchain_stats" ADD COLUMN "active_addresses_cnt_diff" integer NULL;

ALTER TABLE "flat"."blockchain_stats" ADD COLUMN "ibc_active_addresses_percent" numeric NULL;

CREATE TABLE "flat"."tokens"("blockchain" varchar NOT NULL, "denom" varchar NOT NULL, "symbol" varchar, "logo_url" varchar, "price" numeric, "price_day_diff_percent" numeric, "price_week_diff_percent" numeric, "market_cap" bigint, "on_chain_supply" bigint, "token_day_trading_volume" bigint, "token_day_trading_volume_diff_percent" numeric, PRIMARY KEY ("blockchain","denom") , FOREIGN KEY ("blockchain") REFERENCES "flat"."blockchains"("network_id") ON UPDATE restrict ON DELETE restrict);

CREATE TABLE "flat"."token_chart_type"("chart_type" varchar NOT NULL, PRIMARY KEY ("chart_type") );

CREATE TABLE "flat"."token_charts"("blockchain" varchar NOT NULL, "denom" varchar NOT NULL, "chart_type" varchar NOT NULL, "point_index" integer NOT NULL, "point_value" numeric NOT NULL, PRIMARY KEY ("blockchain","denom","chart_type","point_index") , FOREIGN KEY ("blockchain", "denom") REFERENCES "flat"."tokens"("blockchain", "denom") ON UPDATE restrict ON DELETE restrict, FOREIGN KEY ("chart_type") REFERENCES "flat"."token_chart_type"("chart_type") ON UPDATE restrict ON DELETE restrict);

ALTER TABLE "flat"."blockchains" ADD COLUMN "base_token" varchar NULL;

alter table "flat"."blockchains"
           add constraint "blockchains_network_id_base_token_fkey"
           foreign key ("network_id", "base_token")
           references "flat"."tokens"
           ("blockchain", "denom") on update restrict on delete restrict;

ALTER TABLE "flat"."blockchains" ADD COLUMN "inflation" numeric NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "staking_apr" numeric NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "unbonding_period" integer NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "bonded_tokens" bigint NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "bonded_tokens_percent" numeric NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "validators_cnt" integer NULL;

ALTER TABLE "flat"."blockchains" ADD COLUMN "nodes_cnt" integer NULL;
