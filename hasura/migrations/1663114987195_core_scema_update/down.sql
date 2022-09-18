
alter table "public"."zones" drop constraint "zones_base_token_denom_chain_id_fkey";

ALTER TABLE "public"."zones" DROP COLUMN "base_token_denom";
