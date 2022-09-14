
alter table "flat"."blockchain_relations" drop constraint "blockchain_relations_pkey";
alter table "flat"."blockchain_relations"
    add constraint "blockchain_relations_pkey" 
    primary key ( "timeframe", "blockchain_target", "blockchain_source" );

ALTER TABLE "flat"."blockchain_relations" DROP COLUMN "is_mainnet";
