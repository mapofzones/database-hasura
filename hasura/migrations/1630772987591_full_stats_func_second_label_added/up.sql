DROP FUNCTION IF EXISTS public.get_full_stats_for_each_zone(integer, integer);

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
    zone_label_url2 varchar
);

CREATE OR REPLACE FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF temp_t_full_stats_for_each
 LANGUAGE sql
 STABLE
AS $function$

--ibc transfer start
with previous_with_current_interval as (
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
                ibc_transfer_hourly_stats
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
                ibc_transfer_hourly_stats
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
), union_stats_by_hour as (
    select 
        stats_tx_activities_in_hour.name as zone,
        stats_tx_activities_in_hour.hour as hour,
        CASE WHEN zones_in_stats_tx_activities.txs is NULL THEN 0 ELSE zones_in_stats_tx_activities.txs END AS txs
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
        addr_stats.total_active_addresses_diff as total_active_addresses_diff
    from ibc_transfer_stats as ibc
    left join ibc_in_stats as ibc_in on ibc_in.zone = ibc.zone
    left join ibc_out_stats as ibc_out on ibc_out.zone = ibc.zone
    left join tx_general_stats as tx_stats on tx_stats.zone = ibc.zone
    left join addresses_stats as addr_stats on addr_stats.zone = ibc.zone
)
-- tx stats aggregator end



--calculate rating start
, calculate_rating_and_weight as (
    select
        zone,
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
        -- rating
        row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS total_ibc_txs_rating,
        (row_number() OVER (Order By total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as total_ibc_txs_rating_diff,
        
        row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS ibc_tx_in_rating,
        (row_number() OVER (Order By ibc_tx_in_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as ibc_tx_in_rating_diff,
        
        row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS ibc_tx_out_rating,
        (row_number() OVER (Order By ibc_tx_out_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as ibc_tx_out_rating_diff,
        
        row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, zone asc)::int AS total_txs_rating,
        (row_number() OVER (Order By total_txs_previous desc, total_ibc_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, zone asc))::int as total_txs_rating_diff,
        
        row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, zone asc)::int AS total_active_addresses_rating,
        (row_number() OVER (Order By active_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, zone asc) - row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, zone asc))::int as total_active_addresses_rating_diff,
        
        --weight
        total_ibc_txs / (select case when sum(total_ibc_txs) = 0 then 1 else sum(total_ibc_txs) end from aggregated_tx_stats limit 1)::numeric as total_ibc_txs_weight,
        total_txs / (select case when sum(total_txs) = 0 then 1 else sum(total_txs) end from aggregated_tx_stats limit 1)::numeric as total_txs_weight,
        ibc_tx_in / (select case when sum(ibc_tx_in) = 0 then 1 else sum(ibc_tx_in) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_in_weight,
        ibc_tx_out / (select case when sum(ibc_tx_out) = 0 then 1 else sum(ibc_tx_out) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_out_weight,
        total_active_addresses / (select case when sum(total_active_addresses) = 0 then 1 else sum(total_active_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_addresses_weight
        
    from aggregated_tx_stats
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
        stats.total_active_addresses_diff
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
        zone,
        -- rating
        row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS total_ibc_txs_mainnet_rating,
        (row_number() OVER (Order By total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as total_ibc_txs_mainnet_rating_diff,
        
        row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS ibc_tx_in_mainnet_rating,
        (row_number() OVER (Order By ibc_tx_in_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By ibc_tx_in desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as ibc_tx_in_mainnet_rating_diff,
        
        row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc)::int AS ibc_tx_out_mainnet_rating,
        (row_number() OVER (Order By ibc_tx_out_previous desc, total_ibc_txs_previous desc, total_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By ibc_tx_out desc, total_ibc_txs desc, total_txs desc, total_active_addresses desc, zone asc))::int as ibc_tx_out_mainnet_rating_diff,
        
        row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, zone asc)::int AS total_txs_mainnet_rating,
        (row_number() OVER (Order By total_txs_previous desc, total_ibc_txs_previous desc, active_addrs_past desc, zone asc) - row_number() OVER (Order By total_txs desc, total_ibc_txs desc, total_active_addresses desc, zone asc))::int as total_txs_mainnet_rating_diff,
        
        row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, zone asc)::int AS total_active_addresses_mainnet_rating,
        (row_number() OVER (Order By active_addrs_past desc, total_ibc_txs_previous desc, total_txs_previous desc, zone asc) - row_number() OVER (Order By total_active_addresses desc, total_ibc_txs desc, total_txs desc, zone asc))::int as total_active_addresses_mainnet_rating_diff,
        
        --weight
        total_ibc_txs / (select case when sum(total_ibc_txs) = 0 then 1 else sum(total_ibc_txs) end from aggregated_tx_stats limit 1)::numeric as total_ibc_txs_mainnet_weight,
        total_txs / (select case when sum(total_txs) = 0 then 1 else sum(total_txs) end from aggregated_tx_stats limit 1)::numeric as total_txs_mainnet_weight,
        ibc_tx_in / (select case when sum(ibc_tx_in) = 0 then 1 else sum(ibc_tx_in) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_in_mainnet_weight,
        ibc_tx_out / (select case when sum(ibc_tx_out) = 0 then 1 else sum(ibc_tx_out) end from aggregated_tx_stats limit 1)::numeric as ibc_tx_out_mainnet_weight,
        total_active_addresses / (select case when sum(total_active_addresses) = 0 then 1 else sum(total_active_addresses) end from aggregated_tx_stats limit 1)::numeric as total_active_addresses_mainnet_weight
        
    from
        aggregated_tx_stats_mainnet
)
--calculate mainnet rating end

select
    zones.chain_id as zone,
    calc.total_txs as total_txs,
    calc.total_ibc_txs as total_ibc_txs,
    ibc_percent.percent as ibc_percent,
    calc.ibc_tx_out as ibc_tx_out,
    calc.ibc_tx_in as ibc_tx_in,
    CASE WHEN channels.channels is NULL THEN 0 ELSE channels.channels END::int  as channels_num,
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
    calc.total_active_addresses as total_active_addresses,
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
    blocks_log.last_updated_at > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 1) as is_zone_up_to_date,
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
    zones.zone_label_url2 as zone_label_url2
from
    zones
left join blocks_log on zones.chain_id = blocks_log.zone
left join calculate_rating_and_weight as calc on zones.chain_id = calc.zone
left join ibc_tx_percent_on_period as ibc_percent on zones.chain_id = ibc_percent.zone
left join ibc_channels_stats as channels on zones.chain_id = channels.zone
left join ibc_tx_activities as charts on zones.chain_id = charts.zone
left join calculate_mainnet_rating_and_weight as calc_mainnet on zones.chain_id = calc_mainnet.zone;

$function$;
