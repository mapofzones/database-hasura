alter table "public"."total_tx_hourly_stats"
           add constraint "total_tx_hourly_stats_period_fkey"
           foreign key ("period")
           references "public"."periods"
           ("period_in_hours") on update restrict on delete restrict;
