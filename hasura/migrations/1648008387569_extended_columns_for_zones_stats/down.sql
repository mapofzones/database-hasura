DROP FUNCTION IF EXISTS public.get_full_stats_for_each_zone(integer, integer, boolean);

DROP TYPE IF EXISTS public.temp_t_full_stats_for_each;

CREATE TYPE public.temp_t_full_stats_for_each as (
    zone character varying,
    total_txs integer,
    total_ibc_txs integer,
    ibc_percent numeric,
    ibc_tx_out integer,
    ibc_tx_in integer,
    channels_num integer,
    chart json,
    total_txs_rating integer,
    total_txs_diff integer,
    total_txs_rating_diff integer,
    total_ibc_txs_rating integer,
    total_ibc_txs_diff integer,
    total_ibc_txs_rating_diff integer,
    ibc_tx_in_rating integer,
    ibc_tx_in_diff integer,
    ibc_tx_in_rating_diff integer,
    ibc_tx_out_rating integer,
    ibc_tx_out_diff integer,
    ibc_tx_out_rating_diff integer,
    total_ibc_txs_weight numeric,
    total_txs_weight numeric,
    ibc_tx_in_weight numeric,
    ibc_tx_out_weight numeric,
    total_active_addresses_weight numeric,
    ibc_tx_failed integer,
    ibc_tx_failed_diff integer,
    total_active_addresses integer,
    total_active_addresses_diff integer,
    total_active_addresses_rating integer,
    total_active_addresses_rating_diff integer,
    total_coin_turnover_amount numeric,
    total_coin_turnover_amount_diff numeric,
    ibc_tx_in_failed integer,
    ibc_tx_out_failed integer,
    zone_label_url varchar,
    is_zone_mainnet bool,
    is_zone_new bool,
    is_zone_up_to_date bool,
    zone_readable_name varchar,
    ibc_tx_in_mainnet_rating integer,
    total_active_addresses_mainnet_weight numeric,
    total_active_addresses_mainnet_rating_diff integer,
    total_active_addresses_mainnet_rating integer,
    total_ibc_txs_mainnet_rating_diff integer,
    ibc_tx_out_mainnet_rating_diff integer,
    total_txs_mainnet_rating_diff integer,
    ibc_tx_in_mainnet_rating_diff integer,
    total_ibc_txs_mainnet_weight numeric,
    total_ibc_txs_mainnet_rating integer,
    ibc_tx_out_mainnet_weight numeric,
    ibc_tx_out_mainnet_rating integer,
    total_txs_mainnet_weight numeric,
    total_txs_mainnet_rating integer,
    ibc_tx_in_mainnet_weight numeric,
    zone_label_url2 varchar,
    cashflow bigint,
    cashflow_out bigint,
    cashflow_in bigint,
    cashflow_diff bigint,
    cashflow_in_percent numeric,
    cashflow_out_percent numeric,
    cashflow_in_diff bigint,
    cashflow_out_diff bigint,
    ibc_cashflow_rating integer,
    ibc_cashflow_in_rating integer,
    ibc_cashflow_out_rating integer,
    ibc_cashflow_rating_diff integer,
    ibc_cashflow_in_rating_diff integer,
    ibc_cashflow_out_rating_diff integer,
    ibc_cashflow_weight numeric,
    ibc_cashflow_in_weight numeric,
    ibc_cashflow_out_weight numeric,
    ibc_cashflow_mainnet_rating integer,
    ibc_cashflow_in_mainnet_rating integer,
    ibc_cashflow_out_mainnet_rating integer,
    ibc_cashflow_mainnet_rating_diff integer,
    ibc_cashflow_in_mainnet_rating_diff integer,
    ibc_cashflow_out_mainnet_rating_diff integer,
    ibc_cashflow_mainnet_weight numeric,
    ibc_cashflow_in_mainnet_weight numeric,
    ibc_cashflow_out_mainnet_weight numeric,
    ibc_peers integer,
    ibc_peers_mainnet integer,

    ibc_cashflow_pending bigint,
    ibc_cashflow_in_pending bigint,
    ibc_cashflow_out_pending bigint,
    chart_cashflow jsonb,

    ibc_transfers integer,
    ibc_transfers_diff integer,
    ibc_transfers_pending integer,
    ibc_transfers_mainnet_rating integer,
    ibc_transfers_mainnet_rating_diff integer,
    ibc_transfers_mainnet_weight numeric,
    ibc_transfers_rating integer,
    ibc_transfers_rating_diff integer,
    ibc_transfers_weight numeric,
    success_rate numeric,

    ibc_active_addresses integer,
    ibc_active_addresses_diff integer,
    ibc_active_addresses_rating integer,
    ibc_active_addresses_rating_diff integer,
    ibc_active_addresses_weight numeric,
    ibc_active_addresses_mainnet_rating integer,
    ibc_active_addresses_mainnet_rating_diff integer,
    ibc_active_addresses_mainnet_weight numeric
);

CREATE OR REPLACE FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_full_stats_for_each
 LANGUAGE sql
 STABLE
AS $function$

with zones_statuses as (
    select
        zone,
        status
    from
        get_zones_statuses()
)


--ibc transfer start
, previous_with_current_interval as (
    select
        zone_src,
        zone_dest,
        txs_cnt,
        txs_fail_cnt,
        hour
    from
        ibc_transfer_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_src
        union all
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_dest
    ) as a
    group by zone
), previous_interval_stats as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_src
        union all
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_dest
    ) as a
    group by zone
), ibc_transfer_stats as (
    select
        current.zone as zone,
        current.txs as txs,
        current.txs - previous.txs as txs_diff,
        previous.txs as txs_previous
    from current_interval_stats as current
    left join previous_interval_stats as previous on current.zone = previous.zone
)
--ibc transfer end




--general tx start
, previous_with_current_interval_gerenal as (
    select
        zone,
        txs_cnt,
        hour,
        txs_w_ibc_xfer_fail_cnt,
        total_coin_turnover_amount
    from
        total_tx_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats_gerenal as (
    select
        zone,
        sum(txs_cnt) :: int as txs,
        sum(txs_w_ibc_xfer_fail_cnt) :: int as txs_ibc_fail,
        sum(total_coin_turnover_amount) :: numeric as turnover_amount
    from
    (
        select
            CASE
                WHEN zone is NULL THEN chain_id
                ELSE zone
            END AS zone,
            CASE
                WHEN txs_cnt is NULL THEN 0
                ELSE txs_cnt
            END AS txs_cnt,
            CASE
                WHEN txs_w_ibc_xfer_fail_cnt is NULL THEN 0
                ELSE txs_w_ibc_xfer_fail_cnt
            END AS txs_w_ibc_xfer_fail_cnt,
            CASE
                WHEN total_coin_turnover_amount is NULL THEN 0
                ELSE total_coin_turnover_amount
            END AS total_coin_turnover_amount
        from
        (
            select
                zone,
                txs_cnt,
                txs_w_ibc_xfer_fail_cnt,
                total_coin_turnover_amount
            from
                previous_with_current_interval_gerenal
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as a
        right join zones on zones.chain_id = a.zone
    ) as b
    group by zone
), previous_interval_stats_gerenal as (
    select
        zone,
        sum(txs_cnt) :: int as txs,
        sum(txs_w_ibc_xfer_fail_cnt) :: int as txs_ibc_fail,
        sum(total_coin_turnover_amount) :: numeric as turnover_amount
    from
    (
        select
            CASE
            WHEN zone is NULL THEN chain_id
            ELSE zone
        END AS zone,
        CASE
            WHEN txs_cnt is NULL THEN 0
            ELSE txs_cnt
        END AS txs_cnt,
        CASE
            WHEN txs_w_ibc_xfer_fail_cnt is NULL THEN 0
            ELSE txs_w_ibc_xfer_fail_cnt
        END AS txs_w_ibc_xfer_fail_cnt,
        CASE
            WHEN total_coin_turnover_amount is NULL THEN 0
            ELSE total_coin_turnover_amount
        END AS total_coin_turnover_amount
        from
        (
            select
                zone,
                txs_cnt,
                txs_w_ibc_xfer_fail_cnt,
                total_coin_turnover_amount
            from
                previous_with_current_interval_gerenal
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours =>period_in_hours)
        ) as a
        right join zones on zones.chain_id = a.zone
    ) as b
    group by zone
), tx_general_stats as (
    select
        current.zone as zone,
        current.txs as txs,
        current.txs - previous.txs as txs_diff,
        previous.txs as txs_previous,
        current.txs_ibc_fail as txs_ibc_fail,
        current.txs_ibc_fail - previous.txs_ibc_fail as txs_ibc_fail_diff,
        current.turnover_amount as total_coin_turnover_amount,
        current.turnover_amount - previous.turnover_amount as total_coin_turnover_amount_diff
    from current_interval_stats_gerenal as current
    left join previous_interval_stats_gerenal as previous on current.zone = previous.zone
)
--general tx end





--ibc out start
, current_interval_stats_out_tx as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs,
        CASE WHEN sum(txs_failed)::int is NULL THEN 0 ELSE sum(txs_failed)::int  END as txs_failed
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs,
            txs_fail_cnt as txs_failed
        from (
            select
                zone_src,
                txs_cnt,
                txs_fail_cnt
            from
                previous_with_current_interval
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_src
    ) as a
    group by zone
), previous_interval_stats_out as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_src
    ) as a
    group by zone
), ibc_out_stats as (
    select
        current.zone as zone,
        current.txs as txs,
        previous.txs as txs_previous,
        current.txs - previous.txs as txs_diff,
        current.txs_failed as txs_failed
    from current_interval_stats_out_tx as current
    left join previous_interval_stats_out as previous on current.zone = previous.zone
)
--ibc out end






--ibc in start
, current_interval_stats_in as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs,
        CASE WHEN sum(txs_failed)::int is NULL THEN 0 ELSE sum(txs_failed)::int  END as txs_failed
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs,
            txs_fail_cnt as txs_failed
        from (
            select
                zone_dest,
                txs_cnt,
                txs_fail_cnt
            from
                previous_with_current_interval
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_dest
    ) as a
    group by zone
), previous_interval_stats_in as (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from (
            select
                zone_dest,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.chain_id = stats.zone_dest
    ) as a
    group by zone
), ibc_in_stats as (
    select
        current.zone as zone,
        current.txs as txs,
        previous.txs as txs_previous,
        current.txs - previous.txs as txs_diff,
        current.txs_failed as txs_failed
    from current_interval_stats_in as current
    left join previous_interval_stats_in as previous on current.zone = previous.zone
)
--ibc in end


--ibc percent start
, ibc_stats_current_interval as (
    select
            zone_src,
            zone_dest,
            txs_cnt
        from
            ibc_transfer_hourly_stats
        where
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), ibc_tx_percent_on_period as (
    select
        ibc.zone,
        CASE ibc.txs WHEN 0 THEN 0 ELSE 100 * ibc.txs::decimal / (ibc.txs::decimal + tx.tx::decimal) END AS percent
    from
    (
    select
        zone as zone,
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from
            ibc_stats_current_interval
        right join zones on zones.chain_id = ibc_stats_current_interval.zone_src
        union all
        select
            zones.chain_id as zone,
            txs_cnt as txs
        from
            ibc_stats_current_interval
        right join zones on zones.chain_id = ibc_stats_current_interval.zone_dest
    ) as a
    group by zone
    ) as ibc
    left join
    (
    select
        zone,
        sum(txs_cnt)::int as tx
    from (
        select
            CASE WHEN zone is NULL THEN chain_id ELSE zone END AS zone,
            CASE WHEN txs_cnt is NULL THEN 0 ELSE txs_cnt END AS txs_cnt
        from (
            select
                zone,
                txs_cnt
            from
                total_tx_hourly_stats
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as a
        right join zones on zones.chain_id = a.zone
    ) as b
    group by zone
    ) as tx
    on ibc.zone = tx.zone
)
--ibc percent end





--channels stats start
, ibc_channels_stats as (
    select
        zone as zone,
        count(channel_id) channels
    from
        ibc_channels
    group by
        zone
)
--channels stats end











--chart start
, hours_tx_activities as (
  select generate_series(
    date_trunc('hour', now()) - ((period_in_hours)::text||' hour')::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
), stats_tx_activities as (
    select
            zone_src,
            zone_dest,
            txs_cnt,
            hour
        from
            ibc_transfer_hourly_stats
        where
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), stats_tx_activities_in_hour as (
    select
        chain_id as name,
        hour
    from
        hours_tx_activities
    cross join zones
    order by chain_id, hour
), zones_in_stats_tx_activities as (
    select
        zone,
        hour,
        sum(txs) as txs
    from (
        select
            zones.chain_id as zone,
            txs_cnt as txs,
            hour
        from
            stats_tx_activities
        right join zones on zones.chain_id = stats_tx_activities.zone_src
        union all
        select
            zones.chain_id as zone,
            txs_cnt as txs,
            hour
        from
            stats_tx_activities
        right join zones on zones.chain_id = stats_tx_activities.zone_dest
    ) as tx_activity
    group by
        zone,
        hour
), union_stats_by_hour as (
    select
        stats_tx_activities_in_hour.name as zone,
        stats_tx_activities_in_hour.hour as hour,
        COALESCE(zones_in_stats_tx_activities.txs, 0) AS txs
    from
        zones_in_stats_tx_activities
    right join stats_tx_activities_in_hour on stats_tx_activities_in_hour.name = zones_in_stats_tx_activities.zone and stats_tx_activities_in_hour.hour = zones_in_stats_tx_activities.hour
), union_indexed_stats_by_hour as (
    select
        zone,
        hour,
        txs,
        row_number() OVER (partition By zone Order By hour) AS n
    from
        union_stats_by_hour
), stats_tx_activities_by_step as (
    select
        zone,
        sum(txs) txs
    from union_indexed_stats_by_hour
    GROUP BY union_indexed_stats_by_hour.zone, n/step_in_hours
    ORDER BY union_indexed_stats_by_hour.zone, n/step_in_hours
), ibc_tx_activities as (
    select
        zone,
        json_agg(json_build_object('txs', txs)) as chart
    from stats_tx_activities_by_step
    group by zone
)
--chart end




--addresses start
, previous_with_current_addresses_interval as (
    select
        address,
        zone,
        hour
    from
        active_addresses
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
        and period = 1
), current_addresses_interval as (
    select
        count(distinct address) as active_addrs,
        zone
    from
        previous_with_current_addresses_interval
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone
), previous_addresses_interval as (
    select
        count(distinct address) as active_addrs,
        zone
    from
        previous_with_current_addresses_interval
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone
), addresses_stats as (
    select
        zone,
        total_active_addresses,
        active_addrs_past,
        total_active_addresses - active_addrs_past as total_active_addresses_diff
    from (
        select
            zones.chain_id as zone,
            CASE WHEN current_addresses_interval.active_addrs::int is NULL THEN 0 ELSE current_addresses_interval.active_addrs::int  END as total_active_addresses,
            CASE WHEN previous_addresses_interval.active_addrs::int is NULL THEN 0 ELSE previous_addresses_interval.active_addrs::int  END as active_addrs_past
        from
            zones
        left join current_addresses_interval on zones.chain_id = current_addresses_interval.zone
        left join previous_addresses_interval on zones.chain_id = previous_addresses_interval.zone
        order by
            chain_id
    ) as address_prepare_stats
)
--addresses end





--ibc addresses start
, previous_with_current_ibc_addresses_interval as (
    select
        address,
        zone,
        hour
    from
        active_addresses
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
        and period = 1
        and is_internal_transfer = true
), current_ibc_addresses_interval as (
    select
        count(distinct address) as active_addrs,
        zone
    from
        previous_with_current_ibc_addresses_interval
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone
), previous_ibc_addresses_interval as (
    select
        count(distinct address) as active_addrs,
        zone
    from
        previous_with_current_ibc_addresses_interval
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone
), ibc_addresses_stats as (
    select
        zone,
        total_active_addresses,
        active_addrs_past,
        total_active_addresses - active_addrs_past as total_active_addresses_diff
    from (
        select
            zones.chain_id as zone,
            CASE WHEN current_ibc_addresses_interval.active_addrs::int is NULL THEN 0 ELSE current_ibc_addresses_interval.active_addrs::int  END as total_active_addresses,
            CASE WHEN previous_ibc_addresses_interval.active_addrs::int is NULL THEN 0 ELSE previous_ibc_addresses_interval.active_addrs::int  END as active_addrs_past
        from
            zones
        left join current_ibc_addresses_interval on zones.chain_id = current_ibc_addresses_interval.zone
        left join previous_ibc_addresses_interval on zones.chain_id = previous_ibc_addresses_interval.zone
        order by
            chain_id
    ) as ibc_address_prepare_stats
)
--ibc addresses end



-- tx stats aggregator start
, aggregated_tx_stats as (
    select
        ibc.zone,
        ibc.txs as total_ibc_txs,
        ibc.txs_diff as total_ibc_txs_diff,
        ibc.txs_previous as total_ibc_txs_previous,

        ibc_in.txs as ibc_tx_in,
        ibc_in.txs_previous as ibc_tx_in_previous,
        ibc_in.txs_diff as ibc_tx_in_diff,
        ibc_in.txs_failed as ibc_tx_in_failed,

        ibc_out.txs as ibc_tx_out,
        ibc_out.txs_previous as ibc_tx_out_previous,
        ibc_out.txs_diff as ibc_tx_out_diff,
        ibc_out.txs_failed as ibc_tx_out_failed,

        tx_stats.txs as total_txs,
        tx_stats.txs_diff as total_txs_diff,
        tx_stats.txs_ibc_fail as ibc_tx_failed,
        tx_stats.txs_ibc_fail_diff as ibc_tx_failed_diff,
        tx_stats.total_coin_turnover_amount as total_coin_turnover_amount,
        tx_stats.total_coin_turnover_amount_diff as total_coin_turnover_amount_diff,
        tx_stats.txs_previous as total_txs_previous,

        addr_stats.total_active_addresses as total_active_addresses,
        addr_stats.active_addrs_past as active_addrs_past,
        addr_stats.total_active_addresses_diff as total_active_addresses_diff,

        ibc_addr_stats.total_active_addresses as total_active_ibc_addresses,
        ibc_addr_stats.active_addrs_past as active_ibc_addrs_past,
        ibc_addr_stats.total_active_addresses_diff as total_active_ibc_addresses_diff
    from ibc_transfer_stats as ibc
    left join ibc_in_stats as ibc_in on ibc_in.zone = ibc.zone
    left join ibc_out_stats as ibc_out on ibc_out.zone = ibc.zone
    left join tx_general_stats as tx_stats on tx_stats.zone = ibc.zone
    left join addresses_stats as addr_stats on addr_stats.zone = ibc.zone
    left join ibc_addresses_stats as ibc_addr_stats on ibc_addr_stats.zone = ibc.zone
)
-- tx stats aggregator end



--calculate rating start
, calculate_rating_and_weight as (
    select
        stats.zone,
        total_ibc_txs,
        total_ibc_txs_diff,
        ibc_tx_in,
        ibc_tx_in_diff,
        ibc_tx_in_failed,
        ibc_tx_out,
        ibc_tx_out_diff,
        ibc_tx_out_failed,
        total_txs,
        total_txs_diff,
        ibc_tx_failed,
        ibc_tx_failed_diff,
        total_coin_turnover_amount,
        total_coin_turnover_amount_diff,
        total_active_addresses,
        total_active_addresses_diff,
        total_active_ibc_addresses,
        total_active_ibc_addresses_diff,
        -- rating
        row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_ibc_txs_rating,
        (row_number() OVER (Order By total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_ibc_txs_rating_diff,

        row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_tx_in_rating,
        (row_number() OVER (Order By ibc_tx_in_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_tx_in_rating_diff,

        row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_tx_out_rating,
        (row_number() OVER (Order By ibc_tx_out_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_tx_out_rating_diff,

        row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_txs_rating,
        (row_number() OVER (Order By total_txs_previous desc, total_ibc_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_txs_rating_diff,

        row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_active_addresses_rating,
        (row_number() OVER (Order By active_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_active_addresses_rating_diff,

        row_number() OVER (Order By total_active_ibc_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_active_ibc_addresses_rating,
        (row_number() OVER (Order By active_ibc_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_active_ibc_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_active_ibc_addresses_rating_diff,

        --weight
        total_ibc_txs / (select case when sum(total_ibc_txs) = 0 then 1 else sum(total_ibc_txs) end from aggregated_tx_stats limit 1)::numeric as total_ibc_txs_weight,
        total_txs / (select case when sum(total_txs) = 0 then 1 else sum(total_txs) end from aggregated_tx_stats limit 1)::numeric as total_txs_weight,
        ibc_tx_in / (select case when sum(ibc_tx_in) = 0 then 1 else sum(ibc_tx_in) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_in_weight,
        ibc_tx_out / (select case when sum(ibc_tx_out) = 0 then 1 else sum(ibc_tx_out) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_out_weight,
        total_active_addresses / (select case when sum(total_active_addresses) = 0 then 1 else sum(total_active_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_addresses_weight,
        total_active_ibc_addresses / (select case when sum(total_active_ibc_addresses) = 0 then 1 else sum(total_active_ibc_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_ibc_addresses_weight

    from aggregated_tx_stats as stats
    left join zones_statuses as statuses on statuses.zone = stats.zone
)
--calculate rating end


-- tx stats mainnet aggregator start
, aggregated_tx_stats_mainnet as (
    select
        stats.zone,
        stats.total_ibc_txs,
        stats.total_ibc_txs_diff,
        stats.total_ibc_txs_previous,

        stats.ibc_tx_in,
        stats.ibc_tx_in_previous,
        stats.ibc_tx_in_diff,
        stats.ibc_tx_in_failed,

        stats.ibc_tx_out,
        stats.ibc_tx_out_previous,
        stats.ibc_tx_out_diff,
        stats.ibc_tx_out_failed,

        stats.total_txs,
        stats.total_txs_diff,
        stats.ibc_tx_failed,
        stats.ibc_tx_failed_diff,
        stats.total_coin_turnover_amount,
        stats.total_coin_turnover_amount_diff,
        stats.total_txs_previous,

        stats.total_active_addresses,
        stats.active_addrs_past,
        stats.total_active_addresses_diff,

        stats.total_active_ibc_addresses,
        stats.active_ibc_addrs_past,
        stats.total_active_ibc_addresses_diff
    from
        aggregated_tx_stats as stats
    left join zones on zones.chain_id = stats.zone
    where
        zones.is_mainnet = true
)
-- tx stats mainnet aggregator end


--calculate mainnet rating start
, calculate_mainnet_rating_and_weight as (
    select
        stats.zone,
        -- rating
        row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_ibc_txs_mainnet_rating,
        (row_number() OVER (Order By total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_ibc_txs_mainnet_rating_diff,

        row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_tx_in_mainnet_rating,
        (row_number() OVER (Order By ibc_tx_in_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_tx_in_mainnet_rating_diff,

        row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_tx_out_mainnet_rating,
        (row_number() OVER (Order By ibc_tx_out_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_tx_out_mainnet_rating_diff,

        row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_txs_mainnet_rating,
        (row_number() OVER (Order By total_txs_previous desc, total_ibc_txs_previous desc, active_addrs_past desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_txs_mainnet_rating_diff,

        row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_active_addresses_mainnet_rating,
        (row_number() OVER (Order By active_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_active_addresses_mainnet_rating_diff,

        row_number() OVER (Order By total_active_ibc_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS total_active_ibc_addresses_mainnet_rating,
        (row_number() OVER (Order By active_ibc_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By total_active_ibc_addresses desc, total_ibc_txs desc, total_txs desc, statuses.status desc NULLS LAST, stats.zone asc))::int as total_active_ibc_addresses_mainnet_rating_diff,

        --weight
        total_ibc_txs / (select case when sum(total_ibc_txs) = 0 then 1 else sum(total_ibc_txs) end from aggregated_tx_stats limit 1)::numeric as total_ibc_txs_mainnet_weight,
        total_txs / (select case when sum(total_txs) = 0 then 1 else sum(total_txs) end from aggregated_tx_stats limit 1)::numeric as total_txs_mainnet_weight,
        ibc_tx_in / (select case when sum(ibc_tx_in) = 0 then 1 else sum(ibc_tx_in) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_in_mainnet_weight,
        ibc_tx_out / (select case when sum(ibc_tx_out) = 0 then 1 else sum(ibc_tx_out) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_out_mainnet_weight,
        total_active_addresses / (select case when sum(total_active_addresses) = 0 then 1 else sum(total_active_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_addresses_mainnet_weight,
        total_active_ibc_addresses / (select case when sum(total_active_ibc_addresses) = 0 then 1 else sum(total_active_ibc_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_ibc_addresses_mainnet_weight

    from
        aggregated_tx_stats_mainnet as stats
    left join zones_statuses as statuses on statuses.zone = stats.zone
)
--calculate mainnet rating end








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
    from
        channels_cashflow_tracked_stats
        cross join jsonb_array_elements(chart)
)
, channels_cashflow_zone_to_zone_chart as (
    select
        zone,
        key,
        sum(cashflow) as cashflow
    from (
        select
            zone,
            key,
            sum(value) cashflow
        from
            channels_cashflow_tracked_chart_values
        group by
            zone,
            key
        union all
        select
            charts.counterparty_zone as zone,
            charts.key,
            sum(charts.value) cashflow
        from
            channels_cashflow_tracked_chart_values as charts
            left join zones_statuses as statuses
        on charts.counterparty_zone = statuses.zone
        where
            statuses.status is null
        group by
            charts.counterparty_zone,
            charts.key
    ) as chart_data
    group by
        zone,
        key
)
, cashflow_charts as (
    select
        zone,
        json_agg(json_build_object(key, cashflow)) as chart
    from
        channels_cashflow_zone_to_zone_chart
    group by
        zone
)
, cashflow_zones_simple_data as (
    select
        zone,
        sum(cashflow_in) as cashflow_in,
        sum(cashflow_in_diff) as cashflow_in_diff,
        sum(cashflow_in_pending) as cashflow_in_pending,
        sum(cashflow_out) as cashflow_out,
        sum(cashflow_out_diff) as cashflow_out_diff,
        sum(cashflow_out_pending) as cashflow_out_pending
    from
        channels_cashflow_tracked_stats
    group by
        zone
    union all
    select
        stats.counterparty_zone as zone,
        sum(stats.cashflow_out) as cashflow_in,
        sum(stats.cashflow_out_diff) as cashflow_in_diff,
        sum(stats.cashflow_out_pending) as cashflow_in_pending,
        sum(stats.cashflow_in) as cashflow_out,
        sum(stats.cashflow_in_diff) as cashflow_out_diff,
        sum(stats.cashflow_in_pending) as cashflow_out_pending
    from
        channels_cashflow_tracked_stats as stats
    left join zones_statuses as statuses
        on stats.counterparty_zone = statuses.zone
    where
        statuses.status is null
    group by
        stats.counterparty_zone
)
, cashflow_additional_data as (
    select
        zone,
        cashflow_in,
        cashflow_in_diff,
        cashflow_in_pending,
        cashflow_out,
        cashflow_out_diff,
        cashflow_out_pending,
        cashflow_in + cashflow_out as cashflow,
        cashflow_in_diff + cashflow_out_diff as cashflow_diff,
        cashflow_in_pending + cashflow_out_pending as cashflow_pending,
        CASE
        WHEN cashflow_in + cashflow_out = 0 THEN 0 ELSE 100 * cashflow_in::decimal / (cashflow_in::decimal + cashflow_out::decimal)
        END AS cashflow_in_percent,
        CASE
        WHEN cashflow_in + cashflow_out = 0 THEN 0 ELSE 100 * cashflow_out::decimal / (cashflow_in::decimal + cashflow_out::decimal)
        END AS cashflow_out_percent
    from
        cashflow_zones_simple_data
)
, cashflow_additional_all_zones_data as (
    select
        zones.chain_id as zone,
        is_mainnet,
        coalesce(cashflow_in, 0) as cashflow_in,
        coalesce(cashflow_in_diff, 0) as cashflow_in_diff,
        coalesce(cashflow_in_pending, 0) as cashflow_in_pending,
        coalesce(cashflow_out, 0) as cashflow_out,
        coalesce(cashflow_out_diff, 0) as cashflow_out_diff,
        coalesce(cashflow_out_pending, 0) as cashflow_out_pending,
        coalesce(cashflow, 0) as cashflow,
        coalesce(cashflow_diff, 0) as cashflow_diff,
        coalesce(cashflow_pending, 0) as cashflow_pending,
        coalesce(cashflow_in_percent, 0) as cashflow_in_percent,
        coalesce(cashflow_out_percent, 0) as cashflow_out_percent
    from
        zones
        left join cashflow_additional_data as data
    on zones.chain_id = data.zone
)
, cashflow_mainnet_rating_weight as (
    select
        stats.zone,
        -- rating mainnet
        row_number() OVER (Order By cashflow desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_mainnet_rating,
        row_number() OVER (Order By cashflow_in desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_in_mainnet_rating,
        row_number() OVER (Order By cashflow_out desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_out_mainnet_rating,
        -- rating mainnet diff
        (row_number() OVER (Order By cashflow - cashflow_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_mainnet_rating_diff,
        (row_number() OVER (Order By cashflow_in - cashflow_in_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow_in desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_in_mainnet_rating_diff,
        (row_number() OVER (Order By cashflow_out - cashflow_out_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow_out desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_out_mainnet_rating_diff,
        --weight mainnet
        cashflow::numeric / (select case when sum(cf.cashflow) = 0 then 1 else sum(cf.cashflow) end from cashflow_additional_all_zones_data as cf where cf.is_mainnet = true limit 1)::numeric as ibc_cashflow_mainnet_weight,
        cashflow_in::numeric / (select case when sum(cf.cashflow_in) = 0 then 1 else sum(cf.cashflow_in) end from cashflow_additional_all_zones_data as cf where cf.is_mainnet = true limit 1)::numeric as ibc_cashflow_in_mainnet_weight,
        cashflow_out::numeric / (select case when sum(cf.cashflow_out) = 0 then 1 else sum(cf.cashflow_out) end from cashflow_additional_all_zones_data as cf where cf.is_mainnet = true limit 1)::numeric as ibc_cashflow_out_mainnet_weight
    from
        cashflow_additional_all_zones_data as stats
    left join zones_statuses as statuses on statuses.zone = stats.zone
    where
        is_mainnet = true
)
, cashflow_testnet_rating_weight as (
    select
        stats.zone,
        -- rating testnet
        row_number() OVER (Order By cashflow desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_rating,
        row_number() OVER (Order By cashflow_in desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_in_rating,
        row_number() OVER (Order By cashflow_out desc, statuses.status desc NULLS LAST, stats.zone asc)::int AS ibc_cashflow_out_rating,
        -- rating testnet diff
        (row_number() OVER (Order By cashflow - cashflow_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_rating_diff,
        (row_number() OVER (Order By cashflow_in - cashflow_in_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow_in desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_in_rating_diff,
        (row_number() OVER (Order By cashflow_out - cashflow_out_diff desc, statuses.status desc NULLS LAST, stats.zone asc) - row_number() OVER (Order By cashflow_out desc, statuses.status desc NULLS LAST, stats.zone asc))::int as ibc_cashflow_out_rating_diff,
        --weight testnet
        (cashflow)::numeric / (select case when sum(cf.cashflow) = 0 then 1 else sum(cf.cashflow) end from cashflow_additional_all_zones_data as cf limit 1)::numeric as ibc_cashflow_weight,
        (cashflow_in)::numeric / (select case when sum(cf.cashflow_in) = 0 then 1 else sum(cf.cashflow_in) end from cashflow_additional_all_zones_data as cf limit 1)::numeric as ibc_cashflow_in_weight,
        (cashflow_out)::numeric / (select case when sum(cf.cashflow_out) = 0 then 1 else sum(cf.cashflow_out) end from cashflow_additional_all_zones_data as cf limit 1)::numeric as ibc_cashflow_out_weight
    from
        cashflow_additional_all_zones_data as stats
    left join zones_statuses as statuses on statuses.zone = stats.zone
)
-- cashflow end




-- peers start
, peers_data as (
    select distinct
        clients.zone,
        clients.chain_id,
        zones.is_mainnet
    from
        ibc_channels as channels
    left join
        ibc_connections as connections
    on
        channels.zone = connections.zone and channels.connection_id = connections.connection_id
    left join
        ibc_clients as clients
    on
        channels.zone = clients.zone and connections.client_id = clients.client_id
    left join
        zones
    on
        clients.chain_id = zones.chain_id
    where
        is_opened = true
), peers_testnet_included as (
    select
        zone,
        count (*) as peers
    from
        peers_data
    group by
        zone
), peers_mainnet as (
    select
        zone,
        count (*) as peers
    from
        peers_data
    where
        is_mainnet = true
    group by
        zone
), peers as (
    select
        test.zone,
        test.peers as ibc_peers,
        main.peers as ibc_peers_mainnet
    from
        peers_testnet_included as test
    left join
        peers_mainnet as main
    on
        test.zone = main.zone
)
-- peers end






-- recalculated transfers start
, channels_transfers_tracked_stats as (
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
        tx_in,
        tx_in_diff,
        tx_in_pending,
        tx_out,
        tx_out_diff,
        tx_out_pending,
        failed_tx
    from
        get_channels_transfers_stats(period_in_hours, step_in_hours, is_mainnet_only)
)
, transfers_zones_simple_data as (
    select
        zone,
        sum(tx_in) as tx_in,
        sum(tx_in_diff) as tx_in_diff,
        sum(tx_in_pending) as tx_in_pending,
        sum(tx_out) as tx_out,
        sum(tx_out_diff) as tx_out_diff,
        sum(tx_out_pending) as tx_out_pending,
        sum(failed_tx) as failed_tx
    from
        channels_transfers_tracked_stats
    group by
        zone
    union all
    select
        stats.counterparty_zone as zone,
        sum(stats.tx_out) as tx_in,
        sum(stats.tx_out_diff) as tx_in_diff,
        sum(stats.tx_out_pending) as tx_in_pending,
        sum(stats.tx_in) as tx_out,
        sum(stats.tx_in_diff) as tx_out_diff,
        sum(stats.tx_in_pending) as tx_out_pending,
        sum(stats.failed_tx) as failed_tx
    from
        channels_transfers_tracked_stats as stats
        left join zones_statuses as statuses
    on stats.counterparty_zone = statuses.zone
    where
        statuses.status is null
    group by
        stats.counterparty_zone
)
, transfers_additional_data as (
    select
        zone,
        tx_in + tx_out as tx,
        tx_in_diff + tx_out_diff as tx_diff,
        tx_in_pending + tx_out_pending as tx_pending,
        (100.0 * ((tx_in + tx_out)::numeric /
            case
                when (tx_in + tx_out + failed_tx) = 0 then 1
                else tx_in + tx_out + failed_tx
            end))::numeric as ibc_tx_success_rate
    from
        transfers_zones_simple_data
)
, transfers_additional_all_zones_data as (
    select
        zones.chain_id as zone,
        is_mainnet,
        coalesce(tx, 0) as tx,
        coalesce(tx_diff, 0) as tx_diff,
        coalesce(tx_pending, 0) as tx_pending,
        ibc_tx_success_rate
    from
        zones
    left join transfers_additional_data as data
        on zones.chain_id = data.zone
)
, transfers_mainnet_rating_weight as (
    select
        zone,
        -- rating mainnet
        row_number() OVER (Order By tx desc, is_mainnet desc NULLS LAST, zone asc)::int AS ibc_tx_mainnet_rating,
        -- rating mainnet diff
        (row_number() OVER (Order By tx - tx_diff desc, is_mainnet desc NULLS LAST, zone asc) - row_number() OVER (Order By tx desc, is_mainnet desc NULLS LAST, zone asc))::int as ibc_tx_mainnet_rating_diff,
        --weight mainnet
        tx::numeric / (select case when sum(cf.tx) = 0 then 1 else sum(cf.tx) end from transfers_additional_all_zones_data as cf where cf.is_mainnet = true limit 1)::numeric as ibc_tx_mainnet_weight
    from
        transfers_additional_all_zones_data
    where
        is_mainnet = true
)
, transfers_testnet_rating_weight as (
    select
        zone,
        -- rating testnet
        row_number() OVER (Order By tx desc, is_mainnet desc NULLS LAST, zone asc)::int AS ibc_tx_rating,
        -- rating testnet diff
        (row_number() OVER (Order By tx - tx_diff desc, is_mainnet desc NULLS LAST, zone asc) - row_number() OVER (Order By tx desc, is_mainnet desc NULLS LAST, zone asc))::int as ibc_tx_rating_diff,
        --weight testnet
        (tx)::numeric / (select case when sum(cf.tx) = 0 then 1 else sum(cf.tx) end from transfers_additional_all_zones_data as cf limit 1)::numeric as ibc_tx_weight
    from
        transfers_additional_all_zones_data
)
-- recalculated transfers end






select
    zones.chain_id as zone,
    case when calc.total_txs = 0 then NULL else calc.total_txs end as total_txs,
    calc.total_ibc_txs as total_ibc_txs,
    case when calc.total_txs = 0 then NULL else ibc_percent.percent end as ibc_percent,
    calc.ibc_tx_out as ibc_tx_out,
    calc.ibc_tx_in as ibc_tx_in,
    case when calc.total_txs = 0 then NULL else CASE WHEN channels.channels is NULL THEN 0 ELSE channels.channels END::int end as channels_num,
    charts.chart as chart,
    calc.total_txs_rating as total_txs_rating,
    calc.total_txs_diff as total_txs_diff,
    calc.total_txs_rating_diff as total_txs_rating_diff,
    calc.total_ibc_txs_rating as total_ibc_txs_rating,
    calc.total_ibc_txs_diff as total_ibc_txs_diff,
    calc.total_ibc_txs_rating_diff as total_ibc_txs_rating_diff,
    calc.ibc_tx_in_rating as ibc_tx_in_rating,
    calc.ibc_tx_in_diff as ibc_tx_in_diff,
    calc.ibc_tx_in_rating_diff as ibc_tx_in_rating_diff,
    calc.ibc_tx_out_rating as ibc_tx_out_rating,
    calc.ibc_tx_out_diff as ibc_tx_out_diff,
    calc.ibc_tx_out_rating_diff as ibc_tx_out_rating_diff,
    calc.total_ibc_txs_weight as total_ibc_txs_weight,
    calc.total_txs_weight as total_txs_weight,
    calc.ibc_tx_in_weight as ibc_tx_in_weight,
    calc.ibc_tx_out_weight as ibc_tx_out_weight,
    calc.total_active_addresses_weight as total_active_addresses_weight,
    calc.ibc_tx_failed as ibc_tx_failed,
    calc.ibc_tx_failed_diff as ibc_tx_failed_diff,
    case when calc.total_txs = 0 then NULL else calc.total_active_addresses end as total_active_addresses,
    calc.total_active_addresses_diff as total_active_addresses_diff,
    calc.total_active_addresses_rating as total_active_addresses_rating,
    calc.total_active_addresses_rating_diff as total_active_addresses_rating_diff,
    calc.total_coin_turnover_amount as total_coin_turnover_amount,
    calc.total_coin_turnover_amount_diff as total_coin_turnover_amount_diff,
    calc.ibc_tx_in_failed as ibc_tx_in_failed,
    calc.ibc_tx_out_failed as ibc_tx_out_failed,
    zones.zone_label_url as zone_label_url,
    zones.is_mainnet as is_zone_mainnet,
    zones.is_zone_new as is_zone_new,
    zones_statuses.status as is_zone_up_to_date,
    zones.name as zone_readable_name,
    calc_mainnet.ibc_tx_in_mainnet_rating as ibc_tx_in_mainnet_rating,
    calc_mainnet.total_active_addresses_mainnet_weight as total_active_addresses_mainnet_weight,
    calc_mainnet.total_active_addresses_mainnet_rating_diff as total_active_addresses_mainnet_rating_diff,
    calc_mainnet.total_active_addresses_mainnet_rating as total_active_addresses_mainnet_rating,
    calc_mainnet.total_ibc_txs_mainnet_rating_diff as total_ibc_txs_mainnet_rating_diff,
    calc_mainnet.ibc_tx_out_mainnet_rating_diff as ibc_tx_out_mainnet_rating_diff,
    calc_mainnet.total_txs_mainnet_rating_diff as total_txs_mainnet_rating_diff,
    calc_mainnet.ibc_tx_in_mainnet_rating_diff as ibc_tx_in_mainnet_rating_diff,
    calc_mainnet.total_ibc_txs_mainnet_weight as total_ibc_txs_mainnet_weight,
    calc_mainnet.total_ibc_txs_mainnet_rating as total_ibc_txs_mainnet_rating,
    calc_mainnet.ibc_tx_out_mainnet_weight as ibc_tx_out_mainnet_weight,
    calc_mainnet.ibc_tx_out_mainnet_rating as ibc_tx_out_mainnet_rating,
    calc_mainnet.total_txs_mainnet_weight as total_txs_mainnet_weight,
    calc_mainnet.total_txs_mainnet_rating as total_txs_mainnet_rating,
    calc_mainnet.ibc_tx_in_mainnet_weight as ibc_tx_in_mainnet_weight,
    zones.zone_label_url2 as zone_label_url2,

    cashflow.cashflow::bigint,
    cashflow.cashflow_out::bigint,
    cashflow.cashflow_in::bigint,
    cashflow.cashflow_diff::bigint,
    cashflow.cashflow_in_percent,
    cashflow.cashflow_out_percent,
    cashflow.cashflow_in_diff::bigint,
    cashflow.cashflow_out_diff::bigint,

    cashflow_testnet.ibc_cashflow_rating,
    cashflow_testnet.ibc_cashflow_in_rating,
    cashflow_testnet.ibc_cashflow_out_rating,
    cashflow_testnet.ibc_cashflow_rating_diff,
    cashflow_testnet.ibc_cashflow_in_rating_diff,
    cashflow_testnet.ibc_cashflow_out_rating_diff,
    cashflow_testnet.ibc_cashflow_weight,
    cashflow_testnet.ibc_cashflow_in_weight,
    cashflow_testnet.ibc_cashflow_out_weight,

    cashflow_mainnet.ibc_cashflow_mainnet_rating,
    cashflow_mainnet.ibc_cashflow_in_mainnet_rating,
    cashflow_mainnet.ibc_cashflow_out_mainnet_rating,
    cashflow_mainnet.ibc_cashflow_mainnet_rating_diff,
    cashflow_mainnet.ibc_cashflow_in_mainnet_rating_diff,
    cashflow_mainnet.ibc_cashflow_out_mainnet_rating_diff,
    cashflow_mainnet.ibc_cashflow_mainnet_weight,
    cashflow_mainnet.ibc_cashflow_in_mainnet_weight,
    cashflow_mainnet.ibc_cashflow_out_mainnet_weight,

    peers.ibc_peers::int,
    peers.ibc_peers_mainnet::int,
    cashflow.cashflow_pending::bigint as ibc_cashflow_pending,
    cashflow.cashflow_in_pending::bigint as ibc_cashflow_in_pending,
    cashflow.cashflow_out_pending::bigint as ibc_cashflow_out_pending,
    coalesce(cashflow_charts.chart, '[]')::jsonb as chart_cashflow,

    transfers.tx::integer as ibc_transfers,
    transfers.tx_diff::integer as ibc_transfers_diff,
    transfers.tx_pending::integer as ibc_transfers_pending,
    transfers_mainnet.ibc_tx_mainnet_rating::integer as ibc_transfers_mainnet_rating,
    transfers_mainnet.ibc_tx_mainnet_rating_diff::integer as ibc_transfers_mainnet_rating_diff,
    transfers_mainnet.ibc_tx_mainnet_weight::numeric as ibc_transfers_mainnet_weight,
    transfers_testnet.ibc_tx_rating::integer as ibc_transfers_rating,
    transfers_testnet.ibc_tx_rating_diff::integer as ibc_transfers_rating_diff,
    transfers_testnet.ibc_tx_weight::numeric as ibc_transfers_weight,
    transfers.ibc_tx_success_rate::numeric as success_rate,

    calc.total_active_ibc_addresses::integer as ibc_active_addresses,
    calc.total_active_ibc_addresses_diff::integer as ibc_active_addresses_diff,
    calc.total_active_ibc_addresses_rating::integer as ibc_active_addresses_rating,
    calc.total_active_ibc_addresses_rating_diff::integer as ibc_active_addresses_rating_diff,
    calc.total_active_ibc_addresses_weight::numeric as ibc_active_addresses_weight,
    calc_mainnet.total_active_ibc_addresses_mainnet_rating::integer as ibc_active_addresses_mainnet_rating,
    calc_mainnet.total_active_ibc_addresses_mainnet_rating_diff::integer as ibc_active_addresses_mainnet_rating_diff,
    calc_mainnet.total_active_ibc_addresses_mainnet_weight::numeric as ibc_active_addresses_mainnet_weight
from
    zones
left join calculate_rating_and_weight as calc on zones.chain_id = calc.zone
left join ibc_tx_percent_on_period as ibc_percent on zones.chain_id = ibc_percent.zone
left join ibc_channels_stats as channels on zones.chain_id = channels.zone
left join ibc_tx_activities as charts on zones.chain_id = charts.zone
left join calculate_mainnet_rating_and_weight as calc_mainnet on zones.chain_id = calc_mainnet.zone
left join cashflow_additional_all_zones_data as cashflow on zones.chain_id = cashflow.zone
left join cashflow_mainnet_rating_weight as cashflow_mainnet on zones.chain_id = cashflow_mainnet.zone
left join cashflow_testnet_rating_weight as cashflow_testnet on zones.chain_id = cashflow_testnet.zone
left join cashflow_charts as cashflow_charts on zones.chain_id = cashflow_charts.zone
left join peers on zones.chain_id = peers.zone
left join transfers_additional_all_zones_data as transfers on zones.chain_id = transfers.zone
left join transfers_mainnet_rating_weight as transfers_mainnet on zones.chain_id = transfers_mainnet.zone
left join transfers_testnet_rating_weight as transfers_testnet on zones.chain_id = transfers_testnet.zone
left join zones_statuses on zones_statuses.zone = zones.chain_id;

$function$;
