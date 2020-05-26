alter table "public"."blocks_log"
           add constraint "blocks_log_zone_fkey"
           foreign key ("zone")
           references "public"."zones"
           ("chain_id") on update restrict on delete restrict;
