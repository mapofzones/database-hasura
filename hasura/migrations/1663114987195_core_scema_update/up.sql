
ALTER TABLE "public"."zones" ADD COLUMN "base_token_denom" varchar NULL;

alter table "public"."zones"
           add constraint "zones_base_token_denom_chain_id_fkey"
           foreign key ("base_token_denom", "chain_id")
           references "public"."tokens"
           ("base_denom", "zone") on update restrict on delete restrict;
