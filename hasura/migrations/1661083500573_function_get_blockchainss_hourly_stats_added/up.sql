DROP FUNCTION IF EXISTS public.get_blockchains_hourly_stats(timestamp, integer);

DROP TYPE IF EXISTS public.temp_t_get_blockchains_hourly_stats;

CREATE TYPE public.temp_t_get_blockchains_hourly_stats as (
    network_id character varying,
    timestamp timestamp,
    txs integer
    );

CREATE OR REPLACE FUNCTION public.get_blockchains_hourly_stats(request_timestamp timestamp, period_in_hours integer)
 RETURNS SETOF temp_t_get_blockchains_hourly_stats
 LANGUAGE sql
 STABLE
AS $function$

with series as (
    select generate_series(
        date_trunc('hour', request_timestamp) - ((period_in_hours-1)::text||' hour')::interval,
        date_trunc('hour', request_timestamp),
        '1 hour'::interval
    ) as hour
)
, blockchain_series as (
    select
        chain_id,
        hour
    from
        zones
        cross join series
)

select
    series.chain_id::character varying as network_id,
    series.hour::timestamp as timestamp,
    CASE
        WHEN txs_cnt is NULL THEN 0::integer
        ELSE txs_cnt::integer
    END AS txs
from
    blockchain_series as series
left join total_tx_hourly_stats as stats
    on stats.zone = series.chain_id and stats.hour = series.hour

$function$;
