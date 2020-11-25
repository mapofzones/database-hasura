CREATE OR REPLACE FUNCTION public.get_total_ibc_channels_stats_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_channels
 LANGUAGE sql
 STABLE
AS $function$
select count(*)::int as count
from (
    select distinct 
        zone_src, 
        zone_dest 
    from 
        ibc_transfer_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) as a;
$function$;
