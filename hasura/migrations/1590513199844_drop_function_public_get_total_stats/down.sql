CREATE OR REPLACE FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF fn_table_zones_channels_zones_channels_chart_pair
 LANGUAGE sql
 STABLE
AS $function$
with graph as (
    select
        zone_src as source,
        zone_dest as target,
        txs_cnt as txs
    from
        ibc_tx_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), active_zones as (
    select distinct
        source as zone
    from
        graph
    union all
    select distinct
        target as zone
    from
        graph
), pairs as (
    select
        source,
        target,
        txs
    from (
        select
            source,
            target,
            txs
        from
            graph
        union all
        select
            target as source,
            source as target,
            txs
        from
            graph
        ) as dsf
    where source < target
), top_pair as (
    select distinct
        source,
        target,
        sum(txs) over (partition by source, target) as ibc
    from 
        pairs
    order by ibc desc
    limit 1
), top_pair_stats as (
    select distinct
        source,
        target,
        ibc as ibc,
        (select case  when sum(txs)::int is null then 0 else sum(txs)::int end from graph where top_pair.source=graph.source and top_pair.target=graph.target) as source_to_target_txs,
        (select case  when sum(txs)::int is null then 0 else sum(txs)::int end from graph where top_pair.source=graph.target and top_pair.target=graph.source) as target_to_source_txs
    from 
        top_pair
), top_pair_json as (
    select
        case  when json_agg(json_build_object('source', source, 'target', target, 'ibc', ibc, 'source_to_target_txs', source_to_target_txs, 'target_to_source_txs', target_to_source_txs)) is null then '[]' 
        else json_agg(json_build_object('source', source, 'target', target, 'ibc', ibc, 'source_to_target_txs', source_to_target_txs, 'target_to_source_txs', target_to_source_txs))::jsonb end as top_zone_pair
    from 
        top_pair_stats as pair
)
select
    (select count(name)::int as zones_cnt_all from zones) as zones_cnt_all,
    (select count(*)::int from (select distinct zone_src, zone_dest from ibc_tx_hourly_stats) as all_channels) as channels_cnt_all,
    (select count(active_zones.zone)::int from (select distinct zone from active_zones) as active_zones) as zones_cnt_period,
    ibc_channels.channels as channels_cnt_period,
    ibc_chart.chart as chart,
    (select top_zone_pair from top_pair_json) as top_zone_pair
from
    get_total_ibc_channels_stats_on_period(period_in_hours) as ibc_channels
cross join (
    select 
        json_agg(ibc_chart) chart
    from 
        get_total_ibc_tx_activities_on_period(period_in_hours, step_in_hours) as ibc_chart
    ) as ibc_chart
limit 1
$function$;
