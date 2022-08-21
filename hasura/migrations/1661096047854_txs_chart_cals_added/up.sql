DROP FUNCTION IF EXISTS public.blockchain_tf_charts();

DROP TYPE IF EXISTS public.temp_t_blockchain_tf_charts;

CREATE TYPE public.temp_t_blockchain_tf_charts as (
    blockchain character varying,
    timeframe integer,
    chart_type character varying,
    point_index integer,
    point_value numeric
);

CREATE OR REPLACE FUNCTION public.blockchain_tf_charts(request_timestamp timestamp, period_in_hours integer, step_in_hours integer)
 RETURNS SETOF temp_t_blockchain_tf_charts
 LANGUAGE sql
 STABLE
AS $function$

with hourly_stats as (
    select
        network_id as blockchain,
        row_number() OVER (PARTITION BY network_id order by timestamp) - 1 AS point_step,
        txs as point_value
    from
        intermediate.blockchains_hourly_stats
    where
        timestamp > request_timestamp - make_interval(hours => period_in_hours)
)

select
    blockchain,
    period_in_hours as timeframe,
    'txs' as chart_type,
    (point_step/step_in_hours)::integer as point_index,
    sum(point_value)::numeric as point_value
from
    hourly_stats
group by
    blockchain,
    point_step/step_in_hours

$function$;
