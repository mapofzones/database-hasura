alter table "public"."ft_channel_group_stats" drop constraint "ft_channel_group_stats_pkey";
alter table "public"."ft_channel_group_stats"
    add constraint "ft_channel_group_stats_pkey" 
    primary key ( "timeframe", "zone" );
