CREATE OR REPLACE FUNCTION public.get_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF fn_table_zone_chart
 LANGUAGE sql
 STABLE
AS $function$
with hours as (
  select generate_series(
    date_trunc('hour', now()) - ((period_in_hours)::text||' hour')::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
), stats as (
    select
            zone_src,
            zone_dest,
            txs_cnt,
            hour
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), stats_in_hour as (
    select
        name,
        hour
    from
        hours
    cross join zones
    order by name, hour
), zones_in_stats as (
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats
    right join zones on zones.name = stats.zone_src
    union all
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats
    right join zones on zones.name = stats.zone_dest
), union_stats_by_hour as (
    select 
        stats_in_hour.name as zone,
        stats_in_hour.hour as hour,
        CASE WHEN zones_in_stats.txs is NULL THEN 0 ELSE zones_in_stats.txs END AS txs
    from 
        zones_in_stats
    right join stats_in_hour on stats_in_hour.name = zones_in_stats.zone and stats_in_hour.hour = zones_in_stats.hour
), union_indexed_stats_by_hour as (
    select
        zone,
        hour,
        txs,
        row_number() OVER (partition By zone Order By hour) AS n
    from
        union_stats_by_hour
), stats_by_step as (
    select
        zone,
        sum(txs) txs
    from union_indexed_stats_by_hour
    GROUP BY union_indexed_stats_by_hour.zone, n/step_in_hours
    ORDER BY union_indexed_stats_by_hour.zone, n/step_in_hours
)
select 
    zone,
    json_agg(json_build_object('txs', txs)) as chart
from stats_by_step
group by zone;
$function$;
