alter table "public"."ibc_transfer_hourly_stats"
           add constraint "ibc_transfer_hourly_stats_ibc_channel_zone_fkey"
           foreign key ("ibc_channel", "zone")
           references "public"."ibc_channels"
           ("channel_id", "zone") on update restrict on delete restrict;
