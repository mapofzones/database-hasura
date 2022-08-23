
ALTER TABLE "flat"."blockchain_stats" DROP COLUMN "ibc_active_addresses_cnt_diff";

ALTER TABLE "flat"."blockchain_stats" DROP COLUMN "ibc_active_addresses_cnt";

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_active_addresses_cnt_diff" int4;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_active_addresses_cnt_diff" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_switched_stats" ADD COLUMN "ibc_active_addresses_cnt" int4;
ALTER TABLE "flat"."blockchain_switched_stats" ALTER COLUMN "ibc_active_addresses_cnt" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_relations" ADD COLUMN "is_mainnet" bool;
ALTER TABLE "flat"."blockchain_relations" ALTER COLUMN "is_mainnet" DROP NOT NULL;

alter table "flat"."blockchain_relations" drop constraint "blockchain_relations_pkey";
alter table "flat"."blockchain_relations"
    add constraint "blockchain_relations_pkey" 
    primary key ( "blockchain_source", "blockchain_target", "is_mainnet", "timeframe" );
