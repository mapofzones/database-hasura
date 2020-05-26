alter table "public"."total_tx_hourly_stats" drop constraint "total_tx_hourly_stats_pkey";
alter table "public"."total_tx_hourly_stats"
    add constraint "total_tx_hourly_stats_pkey" 
    primary key ( "zone", "hour" );
