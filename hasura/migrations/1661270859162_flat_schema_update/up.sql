
alter table "flat"."blockchain_relations" drop constraint "blockchain_relations_pkey";
alter table "flat"."blockchain_relations"
    add constraint "blockchain_relations_pkey" 
    primary key ( "blockchain_source", "blockchain_target", "timeframe" );

ALTER TABLE "flat"."blockchain_relations" DROP COLUMN "is_mainnet" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_active_addresses_cnt" CASCADE;

ALTER TABLE "flat"."blockchain_switched_stats" DROP COLUMN "ibc_active_addresses_cnt_diff" CASCADE;

ALTER TABLE "flat"."blockchain_stats" ADD COLUMN "ibc_active_addresses_cnt" integer NOT NULL;

ALTER TABLE "flat"."blockchain_stats" ADD COLUMN "ibc_active_addresses_cnt_diff" integer NOT NULL;
