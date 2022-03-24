DROP FUNCTION IF EXISTS public.get_total_stats(integer, integer, boolean);

DROP TYPE IF EXISTS public.temp_t_total_stats;

CREATE TYPE public.temp_t_total_stats as (
    zones_cnt_all integer,
    channels_cnt_all integer,
    zones_cnt_period integer,
    channels_cnt_period integer,
    chart json,
    top_zone_pair jsonb,
    is_mainnet_only boolean,
    ibc_cashflow_period bigint,
    ibc_cashflow_period_diff bigint,
    top_ibc_cashflow_zone_pair jsonb,
    ibc_cashflow_pending_period bigint,
    ibc_transfers_period integer,
    ibc_transfers_pending_period integer,
    ibc_transfers_period_diff integer,
    chart_transfers json,
    chart_cashflow json,
    top_transfer_zone_pair jsonb,
    ibc_transfers_failed_period integer
);

CREATE OR REPLACE FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_total_stats
 LANGUAGE sql
 STABLE
AS $function$

with
zones_statuses as (
    select
        zone,
        status
    from
        get_zones_statuses()
)
, graph as (
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




-- cashflow start
, channels_cashflow_tracked_stats as (
    select
        zone,
        counterparty_zone,
        channel,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        client_id,
        connection_id,
        is_opened,
        cashflow_in,
        cashflow_in_diff,
        cashflow_in_pending,
        cashflow_out,
        cashflow_out_diff,
        cashflow_out_pending,
        chart
    from
        get_channels_cashflow_stats(period_in_hours, step_in_hours, is_mainnet_only)
)
, channels_cashflow_tracked_chart_values as (
    select
        zone,
        counterparty_zone,
        (value->>jsonb_object_keys(value))::bigint as value,
        jsonb_object_keys(value) as key
    from channels_cashflow_tracked_stats
        cross join jsonb_array_elements(chart)
)
, channels_cashflow_zone_to_zone_chart as (
    select
        key,
        sum(cashflow) as cashflow
    from (
        select
            key,
--             divide 2 because in + out
            sum(value) / 2 cashflow
        from
            channels_cashflow_tracked_chart_values
        group by
            key
        union all
        select
            charts.key,
--             divide 2 because in + out
            sum(charts.value) / 2 cashflow
        from
            channels_cashflow_tracked_chart_values as charts
        left join zones_statuses as statuses
            on charts.counterparty_zone = statuses.zone
        where
            statuses.status is null
        group by
            charts.key
    ) as chart_data
    group by
        key
)
, cashflow_charts as (
    select
        json_agg(json_build_object(key, cashflow)) as chart
    from
        channels_cashflow_zone_to_zone_chart
)
, cashflow_data as (
    select
        sum(cashflow) as cashflow,
        sum(cashflow_diff) as cashflow_diff,
        sum(cashflow_pending) as cashflow_pending
    from (
        select
            sum(cashflow_in) as cashflow,
            sum(cashflow_in_diff) as cashflow_diff,
            sum(cashflow_in_pending + cashflow_out_pending) as cashflow_pending
        from
            channels_cashflow_tracked_stats
        union all
        select
            sum(cashflow_out) as cashflow,
            sum(cashflow_out_diff) as cashflow_diff,
            sum(cashflow_out_pending + cashflow_in_pending) as cashflow_pending
        from
            channels_cashflow_tracked_stats as stats
        left join zones_statuses as statuses
            on stats.counterparty_zone = statuses.zone
        where
            statuses.status is null
    ) as cashflow_data
)
, cashflow_pairs as (
    select
        zone,
        counterparty_zone,
        sum(cashflow_in + cashflow_out) as cashflow,
        sum(cashflow_in) as cashflow_in,
        sum(cashflow_in_diff) as cashflow_in_diff,
        sum(cashflow_in_pending) as cashflow_in_pending,
        sum(cashflow_out) as cashflow_out,
        sum(cashflow_out_diff) as cashflow_out_diff,
        sum(cashflow_out_pending) as cashflow_out_pending
    from
        channels_cashflow_tracked_stats
    group by
        zone,
        counterparty_zone
)
, top_cashflow_pair as (
    select
        zone,
        counterparty_zone,
        cashflow,
        cashflow_in_diff + cashflow_out_diff as cashflow_diff,
        cashflow_in_pending + cashflow_out_pending as cashflow_pending,
        cashflow_in,
        cashflow_out
    from
        cashflow_pairs
    order by
        cashflow desc
        limit 1
)
, top_cashflow_pair_json as (
    select
        coalesce(json_agg(json_build_object(
        'source', one.name,
        'target', two.name,
        'cashflow', cashflow,
        'source_to_target_cashflow', cashflow_out,
        'target_to_source_cashflow', cashflow_in,
        'cashflow_diff', cashflow_diff,
        'cashflow_pending', cashflow_pending
        )), '[]') as top_ibc_cashflow_zone_pair
    from
        top_cashflow_pair as pair
    left join zones as one on one.chain_id = pair.zone
    left join zones as two on two.chain_id = pair.counterparty_zone
)
-- cashflow end




-- new transfer calc start
, channels_transfers_tracked_stats as (
    select
        zone,
        counterparty_zone,
        tx_in,
        tx_in_diff,
        tx_in_pending,
        tx_out,
        tx_out_diff,
        tx_out_pending,
        chart,
        failed_tx
    from
        get_channels_transfers_stats(period_in_hours, step_in_hours, is_mainnet_only)
)
, channels_transfers_tracked_chart_values as (
    select
        zone,
        counterparty_zone,
        (value->>jsonb_object_keys(value))::bigint as value,
        jsonb_object_keys(value) as key
    from channels_transfers_tracked_stats
        cross join jsonb_array_elements(chart)
)
, transfers_chart as (
    select
        key,
        sum(tx) as tx
    from (
        select
            key,
            sum (value) tx
        from
            channels_transfers_tracked_chart_values
        group by
            key
        union all
        select
            charts.key,
            sum (charts.value) tx
        from
            channels_transfers_tracked_chart_values as charts
        left join zones_statuses as statuses
            on charts.counterparty_zone = statuses.zone
        where
            statuses.status is null
        group by
            charts.key
        ) as chart_data
    group by
        key
)
, transfers_charts_json as (
    select
        json_agg(json_build_object(key, tx)) as chart
    from
        transfers_chart
)
, transfers_data as (
    select
        sum(tx) as tx,
        sum(tx_diff) as tx_diff,
        sum(tx_pending) as tx_pending,
        sum(failed_tx) as failed_tx
    from (
        select
            sum(tx_in) as tx,
            sum(tx_in_diff) as tx_diff,
            sum(tx_in_pending + tx_out_pending) as tx_pending,
            sum(failed_tx) as failed_tx
        from
            channels_transfers_tracked_stats
        union all
        select
            sum(tx_out) as tx,
            sum(tx_out_diff) as tx_diff,
            sum(tx_out_pending + tx_in_pending) as tx_pending,
            sum(failed_tx) as failed_tx
        from
            channels_transfers_tracked_stats as stats
        left join zones_statuses as statuses
            on stats.counterparty_zone = statuses.zone
        where
            statuses.status is null
    ) as transfers_data
)
, transfers_pairs as (
    select
        zone,
        counterparty_zone,
        sum(tx_in + tx_out) as tx,
        sum(tx_in) as tx_in,
        sum(tx_in_diff) as tx_in_diff,
        sum(tx_in_pending) as tx_in_pending,
        sum(tx_out) as tx_out,
        sum(tx_out_diff) as tx_out_diff,
        sum(tx_out_pending) as tx_out_pending
    from
        channels_transfers_tracked_stats
    group by
        zone,
        counterparty_zone
)
, top_transfers_pair as (
    select
        zone,
        counterparty_zone,
        tx,
        tx_in_diff + tx_out_diff as tx_diff,
        tx_in_pending + tx_out_pending as tx_pending,
        tx_in,
        tx_out
    from
        transfers_pairs
    order by
        tx desc
        limit 1
)
, top_transfers_pair_json as (
    select
        coalesce(json_agg(json_build_object(
        'source', one.name,
        'target', two.name,
        'txs', pair.tx,
        'source_to_target_txs', pair.tx_out,
        'target_to_source_txs', pair.tx_in,
        'txs_diff', pair.tx_diff,
        'txs_pending', pair.tx_pending
        )), '[]') as top_ibc_tx_zone_pair
    from
        top_transfers_pair as pair
    left join zones as one on one.chain_id = pair.zone
    left join zones as two on two.chain_id = pair.counterparty_zone
)
-- new transfer calc end





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
    coalesce(ibc_chart.chart, '[{"txs":0},{"txs":0}]') as chart,
    (select top_zone_pair from top_pair_json) as top_zone_pair,
    is_mainnet_only as is_mainnet_only,
    cashflow_data.cashflow::bigint as ibc_cashflow_period,
    cashflow_data.cashflow_diff::bigint as ibc_cashflow_period_diff,
    top_cashflow_pair_json.top_ibc_cashflow_zone_pair::jsonb as top_ibc_cashflow_zone_pair,
    cashflow_data.cashflow_pending::bigint as ibc_cashflow_pending_period,
    transfers_data.tx::integer as ibc_transfers_period,
    transfers_data.tx_pending::integer as ibc_transfers_pending_period,
    transfers_data.tx_diff::integer as ibc_transfers_period_diff,
    coalesce(transfers_charts_json.chart, '[{"0":0},{"1":0}]')::json as chart_transfers,
    coalesce(cashflow_charts.chart, '[{"0":0},{"1":0}]')::json as chart_cashflow,
    top_transfers_pair_json.top_ibc_tx_zone_pair::jsonb as top_transfer_zone_pair,
    coalesce(transfers_data.failed_tx, 0)::integer as ibc_transfers_failed_period
from
    total_ibc_channels as ibc_channels
cross join (
    select
        json_agg(ibc_chart) chart
    from 
        total_ibc_tx_activities as ibc_chart
    ) as ibc_chart
cross join
    cashflow_data
cross join
    top_cashflow_pair_json
cross join
    transfers_data
cross join
    transfers_charts_json
cross join
    cashflow_charts
cross join
    top_transfers_pair_json
limit 1

$function$;
