DROP FUNCTION IF EXISTS public.get_channels_series(integer);

DROP TYPE IF EXISTS public.temp_t_get_channels_series;

CREATE TYPE public.temp_t_get_channels_series as (
    zone character varying,
    counterparty_zone character varying,
    channel character varying,
    counterparty_channel character varying,
    is_channel_calculable bool,
    is_counterparty_channel_calculable bool,
    hour timestamp without time zone 
);

CREATE OR REPLACE FUNCTION public.get_channels_series(period_in_hours integer)
 RETURNS SETOF temp_t_get_channels_series
 LANGUAGE sql
 STABLE
AS $function$

with series as (
    select generate_series(
        date_trunc('hour', now()) - ((period_in_hours-1)::text||' hour')::interval,
        date_trunc('hour', now()),
        '1 hour'::interval
    ) as hour
)

select
    zone,
    counterparty_zone,
    channel,
    counterparty_channel,
    is_channel_calculable,
    is_counterparty_channel_calculable,
    hour::timestamp without time zone 
from
    get_channels_info() as channels
cross join series

$function$;
