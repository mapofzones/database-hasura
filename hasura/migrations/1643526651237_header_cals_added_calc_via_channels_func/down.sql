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












-- cashflow start
, previous_with_current_hourly_cashflow as (
    select
        cashflow.zone,
        cashflow.zone_src,
        cashflow.zone_dest,
        cashflow.hour as datetime,
        cashflow.ibc_channel,
        tokens.symbol,
        ((cashflow.amount / POWER(10,tokens.symbol_point_exponent))::bigint * coalesce(prices.coingecko_symbol_price_in_usd, prices.osmosis_symbol_price_in_usd, 0))::bigint as usd_cashflow
    from
        ibc_transfer_hourly_cashflow as cashflow
    inner join
        derivatives
    on
        cashflow.zone = derivatives.zone and cashflow.derivative_denom = derivatives.full_denom
    inner join
        tokens
    on
        derivatives.base_denom = tokens.base_denom and derivatives.origin_zone = tokens.zone
    inner join
        token_prices as prices
    on
        prices.zone = tokens.zone and prices.base_denom = tokens.base_denom and prices.datetime = cashflow.hour
    left join
        zones
    on
        cashflow.zone = zones.chain_id
    where
        tokens.is_price_ignored = false
        and hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
        and (zones.is_mainnet = true or zones.is_mainnet = is_mainnet_only)
    order by
        hour
), current_hourly_cashflow as (
    select
        zone,
        zone_src,
        zone_dest,
        datetime,
        ibc_channel,
        symbol,
        usd_cashflow
    from
        previous_with_current_hourly_cashflow
    where
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), previous_hourly_cashflow as (
    select
        zone,
        zone_src,
        zone_dest,
        datetime,
        ibc_channel,
        symbol,
        usd_cashflow
    from
        previous_with_current_hourly_cashflow
    where
        datetime <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
)

, current_hourly_cashflow_in as (
    select
        zone_dest as zone,
        zone_src as source,
        datetime,
        sum(usd_cashflow) as cashflow
    from
        current_hourly_cashflow as stats
    left join blocks_log
        on stats.zone = blocks_log.zone
    where -- Check to prevent double summation if both zones are monitored
        ((blocks_log.zone is not NULL and stats.zone = stats.zone_dest)
            or blocks_log.zone is NULL)
    group by
        zone_dest,
        zone_src,
        datetime
)

, current_cashflow as (
    select
        zones.chain_id,
        -- Only receiving transfers are taken into account for calculating cash flow
        case
            when current_cashflow_in.cashflow_in is NULL then 0 else current_cashflow_in.cashflow_in
        end as cashflow_in,
        is_mainnet
    from
        zones
    -- Only receiving transfers are taken into account for calculating cash flow
    left join
    (
        select
            zone_dest as zone,
            sum(usd_cashflow) as cashflow_in
        from
            current_hourly_cashflow as cashflow
        left join
            blocks_log
        on
            cashflow.zone = blocks_log.zone
        where -- Check to prevent double summation if both zones are monitored
            (blocks_log.zone is not NULL and cashflow.zone = cashflow.zone_dest)
            or blocks_log.zone is NULL
        group by
            zone_dest
    ) as current_cashflow_in
    on
        zones.chain_id = current_cashflow_in.zone
), previous_cashflow as (
    select
        zones.chain_id,
        -- Only receiving transfers are taken into account for calculating cash flow
        case
            when previous_cashflow_in.cashflow_in is NULL then 0 else previous_cashflow_in.cashflow_in
        end as cashflow_in,
        is_mainnet
    from
        zones
    -- Only receiving transfers are taken into account for calculating cash flow
    left join
    (
        select
            zone_dest as zone,
            sum(usd_cashflow) as cashflow_in
        from
            previous_hourly_cashflow as cashflow
        left join
            blocks_log
        on
            cashflow.zone = blocks_log.zone
        where -- Check to prevent double summation if both zones are monitored
            (blocks_log.zone is not NULL and cashflow.zone = cashflow.zone_dest)
            or blocks_log.zone is NULL
        group by
            zone_dest
    ) as previous_cashflow_in
    on
        zones.chain_id = previous_cashflow_in.zone
)

, current_cashflow_out_by_pair as (
    select
        zone_src as zone,
        zone_dest,
--         ibc_channel,
        sum(usd_cashflow) as cashflow_out
    from
        current_hourly_cashflow as cashflow
    left join
        blocks_log
    on
        cashflow.zone = blocks_log.zone
    where -- Check to prevent double summation if both zones are monitored
        (blocks_log.zone is not NULL and cashflow.zone = cashflow.zone_src)
        or blocks_log.zone is NULL
    group by
        zone_src,
        zone_dest
), current_cashflow_in_by_pair as (
    select
        zone_dest as zone,
        zone_src,
--         ibc_channel,
        sum(usd_cashflow) as cashflow_in
    from
        current_hourly_cashflow as cashflow
    left join
        blocks_log
    on
        cashflow.zone = blocks_log.zone
    where -- Check to prevent double summation if both zones are monitored
        (blocks_log.zone is not NULL and cashflow.zone = cashflow.zone_dest)
        or blocks_log.zone is NULL
    group by
        zone_dest,
        zone_src
), current_pending_cashflow_by_pairs as (
    select
        outcash.zone as zone,
        incash.zone as zone_counterparty,
        case
            when (outcash.cashflow_out - incash.cashflow_in) > 0 then outcash.cashflow_out - incash.cashflow_in else 0
        end as pending
    from
        current_cashflow_out_by_pair as outcash
    left join current_cashflow_in_by_pair as incash
        on outcash.zone = incash.zone_src and outcash.zone_dest = incash.zone
), pending_cashflow as (
    select
        zones.chain_id,
        -- Only output transfers are taken into account for calculating cash flow
        coalesce(current_cashflow_out.pending, 0) as cashflow,
        is_mainnet
    from
        zones
        -- Only output transfers are taken into account for calculating cash flow
        left join
        (
            select
                zone,
                sum(pending) as pending
            from
                current_pending_cashflow_by_pairs as pending_cashflow
            group by
                zone
        ) as current_cashflow_out
    on
        zones.chain_id = current_cashflow_out.zone
), cashflow_data as (
    select
        -- Only receiving transfers are taken into account for calculating cash flow
        sum(current.cashflow_in) as ibc_cashflow_period,
        -- Only receiving transfers are taken into account for calculating cash flow
        sum(current.cashflow_in - previous.cashflow_in) as ibc_cashflow_period_diff,
        -- Only output-input transfers for each pair sum are taken into account for calculating pending cash flow
        sum(pending.cashflow) as ibc_cashflow_pending_period
    from
        current_cashflow as current
    left join
        previous_cashflow as previous
    on
        current.chain_id = previous.chain_id
    left join
        pending_cashflow as pending
    on
        current.chain_id = pending.chain_id
)
-- cashflow end






-- top cashflow pair start
, total_cashflow as (
    select
        cf.zone,
        cf.zone_src as source,
        cf.zone_dest as target,
        case
            when log_dest.zone is not NULL and log_src.zone is not NULL then sum(usd_cashflow)/2 else sum(usd_cashflow)
        end as cashflow
    from
        current_hourly_cashflow as cf
    left join
        blocks_log as log_src
    on
        cf.zone_src = log_src.zone
    left join
        blocks_log as log_dest
    on
        cf.zone_dest = log_dest.zone
    group by
        cf.zone,
        zone_src,
        zone_dest,
        log_src.zone,
        log_dest.zone
), cashflow_pairs as (
    select
        source,
        target,
        case
            when cashflow is NULL then 0 else cashflow
        end as cashflow
    from (
        select
            source,
            target,
            sum(cashflow) as cashflow
        from
            total_cashflow as cf
        left join
            blocks_log
        on
            cf.zone = blocks_log.zone
        where -- Check to prevent double summation if both zones are monitored
            (blocks_log.zone is not NULL and cf.zone = cf.target)
            or blocks_log.zone is NULL
        group by
            source,
            target
        union all
        select
            target as source,
            source as target,
            sum(cashflow) as cashflow
        from
            total_cashflow as cf
        left join
            blocks_log
        on
            cf.zone = blocks_log.zone
        where-- Check to prevent double summation if both zones are monitored
            (blocks_log.zone is not NULL and cf.zone = cf.target)
            or blocks_log.zone is NULL
        group by
            source,
            target
    ) as dsf
    where
        source < target
), cashflow_in_top_pair as (
    select distinct
        source,
        target,
        sum(cashflow) over (partition by source, target) as cashflow
    from
        cashflow_pairs
    order by
        cashflow desc
    limit 1
), cashflow_out_pairs as (
    select
        source,
        target,
        case
            when cashflow is NULL then 0 else cashflow
        end as cashflow
    from (
        select
            source,
            target,
            sum(cashflow) as cashflow
        from
            total_cashflow as cf
        left join
            blocks_log
        on
            cf.zone = blocks_log.zone
        where
            (blocks_log.zone is not NULL and cf.zone = cf.source)
            or blocks_log.zone is NULL
        group by
            source,
            target
        union all
        select
            target as source,
            source as target,
            sum(cashflow) as cashflow
        from
            total_cashflow as cf
        left join
            blocks_log
        on
            cf.zone = blocks_log.zone
        where
            (blocks_log.zone is not NULL and cf.zone = cf.source)
            or blocks_log.zone is NULL
        group by
            source,
            target
    ) as dsf
    where
        source < target
), cashflow_out_top_pair as (
    select distinct
        source,
        target,
        sum(cashflow) over (partition by source, target) as cashflow
    from
        cashflow_out_pairs
)





, previous_total_cashflow as (
    select
        cf.zone,
        cf.zone_src as source,
        cf.zone_dest as target,
        case
            when log_dest.zone is not NULL and log_src.zone is not NULL then sum(usd_cashflow)/2 else sum(usd_cashflow)
        end as cashflow
    from
        previous_hourly_cashflow as cf
    left join blocks_log as log_src
        on cf.zone_src = log_src.zone
    left join blocks_log as log_dest
        on cf.zone_dest = log_dest.zone
    group by
        cf.zone,
        zone_src,
        zone_dest,
        log_src.zone,
        log_dest.zone
), previous_cashflow_pairs as (
    select
        source,
        target,
        case
            when cashflow is NULL then 0 else cashflow
        end as cashflow
    from (
            select
                source,
                target,
                sum(cashflow) as cashflow
            from
                previous_total_cashflow as cf
            left join blocks_log
                on cf.zone = blocks_log.zone
            where -- Check to prevent double summation if both zones are monitored
                (blocks_log.zone is not NULL and cf.zone = cf.target)
                or blocks_log.zone is NULL
            group by
                source,
                target
            union all
            select
                target as source,
                source as target,
                sum(cashflow) as cashflow
            from
                previous_total_cashflow as cf
            left join blocks_log
                on cf.zone = blocks_log.zone
            where-- Check to prevent double summation if both zones are monitored
                (blocks_log.zone is not NULL and cf.zone = cf.target)
                or blocks_log.zone is NULL
            group by
                source,
                target
        ) as dsf
    where
        source < target
), previous_cashflow_in_top_pair as (
    select distinct
        source,
        target,
        sum(cashflow) over (partition by source, target) as cashflow
    from
        previous_cashflow_pairs
)

, cashflow_top_pair as (
    select distinct
        cashflow_in_top_pair.source,
        cashflow_in_top_pair.target,
        cashflow_in_top_pair.cashflow::bigint,
        case
            when (cashflow_out_top_pair.cashflow - cashflow_in_top_pair.cashflow) > 0 then cashflow_out_top_pair.cashflow - cashflow_in_top_pair.cashflow::bigint else 0::bigint
        end as cashflow_pending,
        cashflow_in_top_pair.cashflow::bigint - previous_cashflow_in_top_pair.cashflow::bigint as cashflow_diff
    from
        cashflow_in_top_pair
    left join cashflow_out_top_pair
        on cashflow_in_top_pair.source = cashflow_out_top_pair.source and cashflow_in_top_pair.target = cashflow_out_top_pair.target
    left join previous_cashflow_in_top_pair
        on cashflow_in_top_pair.source = previous_cashflow_in_top_pair.source and cashflow_in_top_pair.target = previous_cashflow_in_top_pair.target
    limit 1
), cashflow_top_pair_stats as (
    select distinct
        source,
        target,
        cashflow::bigint as cashflow,
        (select coalesce(sum(cashflow), 0)::bigint from total_cashflow where cashflow_top_pair.source=total_cashflow.source and cashflow_top_pair.target=total_cashflow.target and total_cashflow.target=total_cashflow.zone)::bigint as source_to_target_cashflow,
        (select coalesce(sum(cashflow), 0)::bigint from total_cashflow where cashflow_top_pair.source=total_cashflow.target and cashflow_top_pair.target=total_cashflow.source and total_cashflow.target=total_cashflow.zone)::bigint as target_to_source_cashflow,
        cashflow_diff,
        cashflow_pending
    from
        cashflow_top_pair
), cashflow_top_pair_json as (
    select
        coalesce(json_agg(json_build_object('source', source, 'target', target, 'cashflow', cashflow, 'source_to_target_cashflow', source_to_target_cashflow, 'target_to_source_cashflow', target_to_source_cashflow, 'cashflow_diff', cashflow_diff, 'cashflow_pending', cashflow_pending)),
            '[]') as top_ibc_cashflow_zone_pair
    from
        cashflow_top_pair_stats as pair
)
-- top cashflow pair end






-- new transfer calc start
, current_with_previous_ibc_stats as (
    select
        zone,
        zone_src as source,
        zone_dest as target,
        hour as datetime,
        sum(txs_cnt - txs_fail_cnt) as txs
    from
        ibc_transfer_hourly_stats as stats
    left join zones as src on src.chain_id = stats.zone_src
    left join zones as dest on dest.chain_id = stats.zone_dest
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours) and
        (src.is_mainnet = true or src.is_mainnet = is_mainnet_only) and
        (dest.is_mainnet = true or dest.is_mainnet = is_mainnet_only)
    group by
        zone,
        zone_src,
        zone_dest,
        hour
)
, previous_ibc_stats_in as (
    select
        target as zone,
        source,
        sum(txs) as txs
    from
        current_with_previous_ibc_stats as stats
    left join blocks_log
        on stats.zone = blocks_log.zone
    where
        datetime <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and ((blocks_log.zone is not NULL and stats.zone = stats.target)
        or blocks_log.zone is NULL)
    group by
        target,
        source
)
, current_hourly_ibc_stats_in as (
    select
        target as zone,
        source,
        datetime,
        sum(txs) as txs
    from
        current_with_previous_ibc_stats as stats
    left join blocks_log
        on stats.zone = blocks_log.zone
    where -- Check to prevent double summation if both zones are monitored
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and ((blocks_log.zone is not NULL and stats.zone = stats.target)
        or blocks_log.zone is NULL)
    group by
        target,
        source,
        datetime
)
, current_ibc_stats_in as (
    select
        zone,
        source,
        sum(txs) as txs
    from
        current_hourly_ibc_stats_in
    group by
        zone,
        source
)
, current_ibc_stats_out as (
    select
        source as zone,
        target,
        sum(txs) as txs
    from
        current_with_previous_ibc_stats as stats
    left join blocks_log
        on stats.zone = blocks_log.zone
    where -- Check to prevent double summation if both zones are monitored
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and ((blocks_log.zone is not NULL and stats.zone = stats.source)
        or blocks_log.zone is NULL)
    group by
        source,
        target
)
, current_ibc_pending_stats as (
    select
        txout.zone as zone,
        txin.zone as zone_counterparty,
        case
            when (txout.txs - txin.txs) > 0 then txout.txs - txin.txs else 0
        end as pending
    from
        current_ibc_stats_out as txout
    left join current_ibc_stats_in as txin
        on txout.zone = txin.source and txout.target = txin.zone
)
, current_ibc_txs as (
    select
        zones.chain_id,
        -- Only receiving transfers are taken into account for calculating cash flow
        coalesce(sum(current_ibc_stats_in.txs), 0) as txs
    from
        zones
    -- Only receiving transfers are taken into account for calculating cash flow
    left join current_ibc_stats_in
        on zones.chain_id = current_ibc_stats_in.zone
    group by
        zones.chain_id
)
, previous_ibc_txs as (
    select
        zones.chain_id,
        -- Only receiving transfers are taken into account for calculating cash flow
        coalesce(sum(previous_ibc_stats_in.txs), 0) as txs
    from
        zones
    -- Only receiving transfers are taken into account for calculating cash flow
    left join previous_ibc_stats_in
        on zones.chain_id = previous_ibc_stats_in.zone
    group by
        zones.chain_id
)
, ibc_pending as (
    select
        zones.chain_id,
        coalesce(sum(current_ibc_pending_stats.pending), 0) as pending
    from
        zones
    left join current_ibc_pending_stats
        on zones.chain_id = current_ibc_pending_stats.zone
    group by
        zones.chain_id
)
, current_ibc_stats as (
    select
        sum(current_ibc_txs.txs) as txs,
        sum(ibc_pending.pending) as pending,
        sum(current_ibc_txs.txs - previous_ibc_txs.txs) as diff
    from
        zones
    left join current_ibc_txs
        on zones.chain_id = current_ibc_txs.chain_id
    left join ibc_pending
        on zones.chain_id = ibc_pending.chain_id
    left join previous_ibc_txs
        on zones.chain_id = previous_ibc_txs.chain_id
)
-- new transfer calc end


-- new transfer calc chart start
, ibc_tx_in_chart as (
    select
        json_agg(ibc_chart) as chart
    from (
            select
                sum(txs)::int AS txs
            from (
                SELECT distinct
                    hour,
                    txs,
                    row_number() OVER (order by hour) AS n
                FROM (
                    select
                        series.hour as hour,
                        coalesce(sum(ibc_data.txs), 0) AS txs
                    from series
                    left join current_hourly_ibc_stats_in as ibc_data
                        on date_trunc('hour', ibc_data.datetime) = series.hour
                    group by
                        1
                ) as a
            ) as b
            GROUP BY n/step_in_hours
            ORDER BY n/step_in_hours
        ) as ibc_chart
)
-- new transfer calc chart end

-- cashflow chart start
, cashflow_chart as (
    select
        json_agg(ibc_chart) as chart
    from (
            select
                sum(cashflow)::bigint AS cashflow
            from (
                SELECT distinct
                    hour,
                    cashflow,
                    row_number() OVER (order by hour) AS n
                FROM (
                    select
                        series.hour as hour,
                        coalesce(sum(ibc_data.cashflow), 0) AS cashflow
                    from series
                    left join current_hourly_cashflow_in as ibc_data
                        on date_trunc('hour', ibc_data.datetime) = series.hour
                    group by
                        1
                ) as a
            ) as b
            GROUP BY n/step_in_hours
            ORDER BY n/step_in_hours
        ) as ibc_chart
)
-- cashflow chart end





-- new transfer calc top pair start
, transfer_in_top_pair as (
    select
        source,
        target,
        sum(txs) as txs
    from (
            select
                zone as target,
                source,
                txs
            from current_ibc_stats_in
            union all
            select
                source as target,
                zone as source,
                txs
            from current_ibc_stats_in
        ) as df
    where
        source > target
    group by
        source,
        target
    order by 3 desc
        limit 1
), previous_transfer_top_pair as (
    select
        source,
        target,
        sum(txs) as txs
    from (
            select
                zone as target,
                source,
                txs
            from previous_ibc_stats_in
            union all
            select
                source as target,
                zone as source,
                txs
            from previous_ibc_stats_in
        ) as df
    where
        source > target
    group by
        source,
        target
), transfer_out_top_pair as (
    select
        source,
        target,
        sum(txs) as txs
    from (
            select
                zone as target,
                zone_counterparty as source,
                pending as txs
            from current_ibc_pending_stats
            union all
            select
                zone_counterparty as target,
                zone as source,
                pending as txs
            from current_ibc_pending_stats
        ) as df
    where
        source > target
    group by
        source,
        target
), transfer_top_pair as (
    select
        transfer_in_top_pair.source,
        transfer_in_top_pair.target,
        transfer_in_top_pair.txs,
        previous_transfer_top_pair.txs - transfer_in_top_pair.txs as txs_diff,
        case
            when (transfer_out_top_pair.txs - transfer_in_top_pair.txs) > 0 then transfer_out_top_pair.txs - transfer_in_top_pair.txs else 0
        end as txs_pending,
        (select coalesce(sum(txs), 0)::bigint from current_ibc_stats_in where transfer_in_top_pair.source=current_ibc_stats_in.source and transfer_in_top_pair.target=current_ibc_stats_in.zone)::bigint as source_to_target_txs,
        (select coalesce(sum(txs), 0)::bigint from current_ibc_stats_in where transfer_in_top_pair.source=current_ibc_stats_in.zone and transfer_in_top_pair.target=current_ibc_stats_in.source)::bigint as target_to_source_txs
    from
        transfer_in_top_pair
    left join previous_transfer_top_pair
        on transfer_in_top_pair.source = previous_transfer_top_pair.source and transfer_in_top_pair.target = previous_transfer_top_pair.target
    left join transfer_out_top_pair
        on transfer_in_top_pair.source = transfer_out_top_pair.source and transfer_in_top_pair.target = transfer_out_top_pair.target
), transfer_top_pair_json as (
    select
        coalesce(json_agg(json_build_object('source', source, 'target', target, 'txs', txs, 'source_to_target_txs', source_to_target_txs, 'target_to_source_txs', target_to_source_txs, 'txs_diff', txs_diff, 'txs_pending', txs_pending)),
        '[]') as top_transfer_zone_pair
    from
        transfer_top_pair as pair
)
-- new transfer calc top pair end







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
    cashflow_data.ibc_cashflow_period::bigint as ibc_cashflow_period,
    cashflow_data.ibc_cashflow_period_diff::bigint as ibc_cashflow_period_diff,
    cashflow_top_pair_json.top_ibc_cashflow_zone_pair::jsonb as top_ibc_cashflow_zone_pair,
    cashflow_data.ibc_cashflow_pending_period::bigint as ibc_cashflow_pending_period,
    current_ibc_stats.txs::integer as ibc_transfers_period,
    current_ibc_stats.pending::integer as ibc_transfers_pending_period,
    current_ibc_stats.diff::integer as ibc_transfers_period_diff,
    coalesce(ibc_tx_in_chart.chart, '[{"txs":0},{"txs":0}]')::json as chart_transfers,
    coalesce(cashflow_chart.chart, '[{"cashflow":0},{"cashflow":0}]')::json as chart_cashflow,
    transfer_top_pair_json.top_transfer_zone_pair::jsonb as top_transfer_zone_pair
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
    cashflow_top_pair_json
cross join
    current_ibc_stats
cross join
    ibc_tx_in_chart
cross join
    cashflow_chart
cross join
    transfer_top_pair_json
limit 1

$function$;
