alter table "public"."ibc_transfer_hourly_stats"
           add constraint "ibc_transfer_hourly_stats_period_fkey"
           foreign key ("period")
           references "public"."periods"
           ("period_in_hours") on update restrict on delete restrict;
