DROP FUNCTION IF EXISTS public.get_blockchain_stats(timestamp, integer);

DROP TYPE IF EXISTS public.temp_t_get_blockchain_stats;

CREATE TYPE public.temp_t_get_blockchain_stats as (
    blockchain character varying,
    timestamp integer,
    txs integer,
    txs_diff integer,
    ibc_active_addresses_cnt integer,
    ibc_active_addresses_cnt_diff integer
);

CREATE OR REPLACE FUNCTION public.get_blockchain_stats(request_timestamp timestamp, period_in_hours integer)
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
, current_active_addresses_lake as (
    select distinct
        address,
        zone
    from
        active_addresses
    where
        hour > request_timestamp - make_interval(hours => period_in_hours)
        and is_internal_transfer = true
)
, current_active_addresses as (
    select
        zone as network_id,
        count(*) as ibc_active_addresses_cnt
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
        and is_internal_transfer = true
)
, previous_active_addresses as (
    select
        zone as network_id,
        count(*) as ibc_active_addresses_cnt
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
    coalesce(current_active_addresses.ibc_active_addresses_cnt, 0)::integer as ibc_active_addresses_cnt,
    coalesce(current_active_addresses.ibc_active_addresses_cnt - previous_active_addresses.ibc_active_addresses_cnt, 0)::integer as ibc_active_addresses_cnt_diff
from
    zones
left join double_interval
    on zones.chain_id = double_interval.network_id
left join current_interval
    on zones.chain_id = current_interval.network_id
left join current_active_addresses
    on zones.chain_id = current_active_addresses.network_id
left join previous_active_addresses
    on zones.chain_id = previous_active_addresses.network_id

$function$;
