DROP FUNCTION IF EXISTS public.get_total_stats(integer, integer, boolean);

DROP TYPE IF EXISTS public.temp_t_total_stats;

CREATE TYPE public.temp_t_total_stats as (
    zones_cnt_all integer,
    channels_cnt_all integer,
    zones_cnt_period integer,
    channels_cnt_period integer,
    chart json,
    top_zone_pair jsonb,
    is_mainnet_only boolean
);

CREATE OR REPLACE FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_total_stats
 LANGUAGE sql
 STABLE
AS $function$

with graph as (
    select
        zone_src as source,
        zone_dest as target,
        txs_cnt as txs
    from
        ibc_transfer_hourly_stats as stats
    left join zones as src on src.chain_id = stats.zone_src
    left join zones as dest on dest.chain_id = stats.zone_dest
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours) and
        (src.is_mainnet = true or src.is_mainnet = is_mainnet_only) and
        (dest.is_mainnet = true or dest.is_mainnet = is_mainnet_only)
        --here +
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
			stats.zone, 
			stats.ibc_channel 
		from 
			ibc_transfer_hourly_stats as stats
        left join zones as zone_current
            on zone_current.chain_id = stats.zone
        left join ibc_channels
            on ibc_channels.zone = stats.zone and ibc_channels.channel_id = stats.ibc_channel
        
        left join ibc_connections as conn
            on conn.zone = ibc_channels.zone and conn.connection_id = ibc_channels.connection_id
        
        left join ibc_clients as clients
            on clients.zone = conn.zone and clients.client_id = conn.client_id
        
        left join zones as zone_dest
            on zone_dest.chain_id = clients.chain_id
            
		where 
			hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours) and
            (zone_current.is_mainnet = true or zone_current.is_mainnet = is_mainnet_only) and
            (zone_dest.is_mainnet = true or zone_dest.is_mainnet = is_mainnet_only)
            --here +
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
            left join zones as zone_src on zone_src.chain_id = ibc_transfer_hourly_stats.zone

            left join ibc_channels
                on ibc_channels.zone = ibc_transfer_hourly_stats.zone and ibc_channels.channel_id = ibc_transfer_hourly_stats.ibc_channel
            left join ibc_connections as conn
                on conn.zone = ibc_channels.zone and conn.connection_id = ibc_channels.connection_id
            left join ibc_clients as clients
                on clients.zone = conn.zone and clients.client_id = conn.client_id
            left join zones as zone_dest
                on zone_dest.chain_id = clients.chain_id

            where
                (zone_src.is_mainnet = true or zone_src.is_mainnet = is_mainnet_only) and
                (zone_dest.is_mainnet = true or zone_dest.is_mainnet = is_mainnet_only)
			group by 1
            --here +
            --need to join check counterparty zone
		) as a
	) as b
	GROUP BY n/step_in_hours
	ORDER BY n/step_in_hours
)
select
    (select count(chain_id)::int as zones_cnt_all from zones where zones.is_mainnet = true or zones.is_mainnet = is_mainnet_only) as zones_cnt_all,
    --here +
    (
        select
            count(*)::int
        from ibc_channels as all_channels
        left join ibc_connections as conn
            on conn.zone = all_channels.zone and conn.connection_id = all_channels.connection_id
        left join ibc_clients as clients
            on clients.zone = conn.zone and clients.client_id = conn.client_id
        left join zones as dest
            on dest.chain_id = clients.chain_id
        left join zones
            on zones.chain_id = all_channels.zone
        where
            (zones.is_mainnet = true or zones.is_mainnet = is_mainnet_only) and
            (dest.is_mainnet = true or dest.is_mainnet = is_mainnet_only)
    ) as channels_cnt_all,
    --here
    (select count(active_zones.zone)::int from (select distinct zone from active_zones) as active_zones) as zones_cnt_period,
    ibc_channels.channels as channels_cnt_period,
    CASE WHEN ibc_chart.chart is NULL THEN '[{"txs":0},{"txs":0}]' ELSE ibc_chart.chart END  as chart,
    (select top_zone_pair from top_pair_json) as top_zone_pair,
    is_mainnet_only as is_mainnet_only
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
