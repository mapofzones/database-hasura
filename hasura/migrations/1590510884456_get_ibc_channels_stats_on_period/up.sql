CREATE OR REPLACE FUNCTION public.get_ibc_channels_stats_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_zone_channels
 LANGUAGE sql
 STABLE
AS $function$
with stats as (
    select distinct
            zone_src,
            zone_dest,
            CASE WHEN txs_cnt is NULL THEN 0 ELSE 1 END  as count
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
)
select 
    zone as zone, 
    sum(count)::int as channels
from (
    select 
        zones.name as zone,
        CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
    from 
        stats
    right join zones on zones.name = stats.zone_src
    union all
    select 
        zones.name as zone,
        CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
    from 
        stats
    right join zones on zones.name = stats.zone_dest
) as a
group by zone;
$function$;
