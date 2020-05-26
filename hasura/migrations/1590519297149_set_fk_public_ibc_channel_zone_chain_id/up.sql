alter table "public"."ibc_channel_zone"
           add constraint "ibc_channel_zone_chain_id_fkey"
           foreign key ("chain_id")
           references "public"."zones"
           ("chain_id") on update restrict on delete restrict;
