alter table "public"."ibc_transfer_hourly_stats" drop constraint "ibc_transfer_hourly_stats_pkey";
alter table "public"."ibc_transfer_hourly_stats"
    add constraint "ibc_tx_hourly_stats_pkey1" 
    primary key ( "zone_dest", "zone", "zone_src", "hour" );
