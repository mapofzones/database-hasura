CREATE OR REPLACE FUNCTION public.get_blockchain_stats(request_timestamp timestamp without time zone, period_in_hours integer)
 RETURNS SETOF temp_t_get_blockchain_stats
 LANGUAGE sql
 STABLE
AS $function$

with double_interval as (
    select
        network_id,
        sum(txs) as txs
    from
        intermediate.blockchains_hourly_stats
    where
        timestamp > request_timestamp - make_interval(hours => 2*period_in_hours)
    group by
        network_id
)
, current_interval as (
    select
        network_id,
        sum(txs) as txs
    from
    intermediate.blockchains_hourly_stats
    where
        timestamp > request_timestamp - make_interval(hours => period_in_hours)
    group by
        network_id
)
, current_ibc_active_addresses_lake as (
    select distinct
        address,
        zone
    from
        active_addresses
    where
        hour > request_timestamp - make_interval(hours => period_in_hours)
        and is_internal_transfer = true
)
, current_ibc_active_addresses as (
    select
        zone as network_id,
        count(*) as ibc_active_addresses_cnt
    from
        current_ibc_active_addresses_lake
    group by
        zone
)
, previous_ibc_active_addresses_lake as (
    select distinct
        address,
        zone
    from
        active_addresses
    where
        hour > request_timestamp - make_interval(hours => 2*period_in_hours)
        and hour < request_timestamp - make_interval(hours => period_in_hours)
        and is_internal_transfer = true
)
, previous_ibc_active_addresses as (
    select
        zone as network_id,
        count(*) as ibc_active_addresses_cnt
    from
        previous_ibc_active_addresses_lake
    group by
        zone
)

, current_active_addresses_lake as (
    select distinct
        address,
        zone
    from
        active_addresses
    where
        hour > request_timestamp - make_interval(hours => period_in_hours)
        and (is_internal_transfer = true or is_internal_tx = true)
)
, current_active_addresses as (
    select
        zone as network_id,
        count(*) as active_addresses_cnt
    from
        current_active_addresses_lake
    group by
        zone
)
, previous_active_addresses_lake as (
    select distinct
        address,
        zone
    from
        active_addresses
    where
        hour > request_timestamp - make_interval(hours => 2*period_in_hours)
        and hour < request_timestamp - make_interval(hours => period_in_hours)
        and (is_internal_transfer = true or is_internal_tx = true)
)
, previous_active_addresses as (
    select
        zone as network_id,
        count(*) as active_addresses_cnt
    from
        previous_active_addresses_lake
    group by
        zone
)

select
    zones.chain_id as blockchain,
    period_in_hours as timestamp,
    coalesce(current_interval.txs, 0)::integer as txs,
    coalesce(current_interval.txs, 0)::integer - coalesce(double_interval.txs, 0)::integer as txs_diff,
    CASE
        WHEN is_active_addresses_hidden = false THEN coalesce(current_ibc_active_addresses.ibc_active_addresses_cnt, 0)::integer
        ELSE NULL::integer
    END as ibc_active_addresses_cnt,
    CASE
        WHEN is_active_addresses_hidden = false THEN coalesce(current_ibc_active_addresses.ibc_active_addresses_cnt - previous_ibc_active_addresses.ibc_active_addresses_cnt, 0)::integer
        ELSE NULL::integer
    END as ibc_active_addresses_cnt_diff,
    coalesce(current_active_addresses.active_addresses_cnt, 0)::integer as active_addresses_cnt,
    coalesce(current_active_addresses.active_addresses_cnt - previous_active_addresses.active_addresses_cnt, 0)::integer as active_addresses_cnt_diff,
    CASE
      WHEN is_active_addresses_hidden = true THEN NULL::NUMERIC
      WHEN (coalesce(current_ibc_active_addresses.ibc_active_addresses_cnt, 0)::NUMERIC  / coalesce(nullif(coalesce(current_active_addresses.active_addresses_cnt, 0), 0), 1)::NUMERIC) * 100.0 > 100 THEN NULL
      ELSE ((coalesce(current_ibc_active_addresses.ibc_active_addresses_cnt, 0)::NUMERIC  / coalesce(nullif(coalesce(current_active_addresses.active_addresses_cnt, 0), 0), 1)::NUMERIC) * 100.0)::NUMERIC
    END as ibc_active_addresses_percent
from
    zones
left join double_interval
    on zones.chain_id = double_interval.network_id
left join current_interval
    on zones.chain_id = current_interval.network_id
left join current_ibc_active_addresses
    on zones.chain_id = current_ibc_active_addresses.network_id
left join previous_ibc_active_addresses
    on zones.chain_id = previous_ibc_active_addresses.network_id

left join current_active_addresses
    on zones.chain_id = current_active_addresses.network_id
left join previous_active_addresses
    on zones.chain_id = previous_active_addresses.network_id

$function$;
