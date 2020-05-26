alter table "public"."ibc_transfer_hourly_stats"
           add constraint "ibc_transfer_hourly_stats_zone_fkey"
           foreign key ("zone")
           references "public"."zones"
           ("chain_id") on update restrict on delete restrict;
