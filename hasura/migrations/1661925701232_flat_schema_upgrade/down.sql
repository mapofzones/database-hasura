
ALTER TABLE "flat"."blockchains" DROP COLUMN "nodes_cnt";

ALTER TABLE "flat"."blockchains" DROP COLUMN "validators_cnt";

ALTER TABLE "flat"."blockchains" DROP COLUMN "bonded_tokens_percent";

ALTER TABLE "flat"."blockchains" DROP COLUMN "bonded_tokens";

ALTER TABLE "flat"."blockchains" DROP COLUMN "unbonding_period";

ALTER TABLE "flat"."blockchains" DROP COLUMN "staking_apr";

ALTER TABLE "flat"."blockchains" DROP COLUMN "inflation";

alter table "flat"."blockchains" drop constraint "blockchains_network_id_base_token_fkey";

ALTER TABLE "flat"."blockchains" DROP COLUMN "base_token";

DROP TABLE "flat"."token_charts";

DROP TABLE "flat"."token_chart_type";

DROP TABLE "flat"."tokens";

ALTER TABLE "flat"."blockchain_stats" DROP COLUMN "ibc_active_addresses_percent";

ALTER TABLE "flat"."blockchain_stats" DROP COLUMN "active_addresses_cnt_diff";

ALTER TABLE "flat"."blockchain_stats" DROP COLUMN "active_addresses_cnt";

ALTER TABLE "flat"."channels_stats" DROP COLUMN "ibc_cashflow_pending";

ALTER TABLE "flat"."channels_stats" DROP COLUMN "ibc_cashflow_diff";

ALTER TABLE "flat"."channels_stats" DROP COLUMN "ibc_cashflow";

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "active_addresses_cnt_rating_diff";

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "active_addresses_cnt_rating";

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_transfers_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_transfers_weight" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_cashflow_out_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_cashflow_out_weight" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_cashflow_in_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_cashflow_in_weight" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_cashflow_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_cashflow_weight" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_active_addresses_cnt_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_active_addresses_cnt_weight" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "txs_weight" numeric;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "txs_weight" DROP NOT NULL;
