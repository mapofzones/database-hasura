alter table "public"."ibc_transfer_hourly_stats" drop constraint "ibc_transfer_hourly_stats_pkey";
alter table "public"."ibc_transfer_hourly_stats"
    add constraint "ibc_transfer_hourly_stats_pkey" 
    primary key ( "hour", "zone_dest", "zone_src", "period", "zone" );
