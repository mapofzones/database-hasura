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
        ibc_transfer_hourly_stats
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
), total_ibc_channels as (
	select count(*)::int as channels
	from (
		select distinct 
			zone_src, 
			zone_dest 
		from 
			ibc_transfer_hourly_stats
		where 
			hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
	) as a
), series as (
	select generate_series(
		date_trunc('hour', now()) - ((period_in_hours-1)::text||' hour')::interval,
		date_trunc('hour', now()),
		'1 hour'::interval
	) as hour
), total_ibc_tx_activities as (
	select 
		(sum(txs_cnt)*2)::int AS txs
	from (
		SELECT distinct hour, txs_cnt, row_number() OVER (order by hour) AS n
		FROM (
			select 
				series.hour as hour,
				CASE WHEN sum(ibc_transfer_hourly_stats.txs_cnt) is NULL THEN 0 ELSE sum(ibc_transfer_hourly_stats.txs_cnt) END AS txs_cnt 
			from series
			left join ibc_transfer_hourly_stats on date_trunc('hour', ibc_transfer_hourly_stats.hour) = series.hour
			group by 1   
		) as a
	) as b
	GROUP BY n/step_in_hours
	ORDER BY n/step_in_hours
)
select
    (select count(name)::int as zones_cnt_all from zones) as zones_cnt_all,
    (select count(*)::int from (select distinct zone_src, zone_dest from ibc_transfer_hourly_stats) as all_channels) as channels_cnt_all,
    (select count(active_zones.zone)::int from (select distinct zone from active_zones) as active_zones) as zones_cnt_period,
    ibc_channels.channels as channels_cnt_period,
    ibc_chart.chart as chart,
    (select top_zone_pair from top_pair_json) as top_zone_pair
from
    total_ibc_channels as ibc_channels
cross join (
    select 
        json_agg(ibc_chart) chart
    from 
        total_ibc_tx_activities as ibc_chart
    ) as ibc_chart
limit 1
$function$;
