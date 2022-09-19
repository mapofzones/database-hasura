DROP FUNCTION IF EXISTS public.get_token_charts(request_timestamp timestamp);

DROP TYPE IF EXISTS public.temp_t_get_token_charts;

CREATE TYPE public.temp_t_get_token_charts as (
    blockchain character varying,
    denom character varying,
    chart_type character varying,
    point_index integer,
    point_value numeric
);

CREATE OR REPLACE FUNCTION public.get_token_charts(request_timestamp timestamp)
 RETURNS SETOF temp_t_get_token_charts
 LANGUAGE sql
 STABLE
AS $function$

with last_known_price as (
    SELECT DISTINCT on (zone, base_denom)
        zone,
        base_denom,
        coingecko_symbol_price_in_usd,
        osmosis_symbol_price_in_usd
    FROM
        public.token_prices
    WHERE
        coingecko_symbol_price_in_usd is NOT NULL
        or osmosis_symbol_price_in_usd is NOT NULL
    ORDER BY
        zone,
        base_denom,
        datetime DESC
)
, tokens_dataset as (
SELECT
    blockchain,
    denom,
    tp.datetime,
    nullif(coalesce(tp.coingecko_symbol_price_in_usd, tp.osmosis_symbol_price_in_usd, lnp.coingecko_symbol_price_in_usd, lnp.osmosis_symbol_price_in_usd, -1), -1) as price_in_usd,
    tp.coingecko_symbol_total_volumes_in_usd as volume_in_usd
FROM
    flat.tokens as t
LEFT JOIN public.token_prices as tp ON tp.zone = t.blockchain and tp.base_denom = t.denom
LEFT JOIN last_known_price as lnp ON lnp.zone = t.blockchain and lnp.base_denom = t.denom
WHERE
    tp.datetime > request_timestamp - make_interval(hours => 720/*month*/)
)


SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'price_monthly'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    price_in_usd::numeric as point_value
FROM
    tokens_dataset
UNION ALL
SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'price_weekly'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    price_in_usd::numeric as point_value
FROM
    tokens_dataset
WHERE
    datetime > request_timestamp - make_interval(hours => 168/*week*/)
UNION ALL
SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'price_daily'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    price_in_usd::numeric as point_value
FROM
    tokens_dataset
WHERE
    datetime > request_timestamp - make_interval(hours => 24/*day*/)
UNION ALL
SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'volume_monthly'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    volume_in_usd::numeric as point_value
FROM
    tokens_dataset
UNION ALL
SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'volume_weekly'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    volume_in_usd::numeric as point_value
FROM
    tokens_dataset
WHERE
    datetime > request_timestamp - make_interval(hours => 168/*week*/)
UNION ALL
SELECT
    blockchain::character varying as network_id,
    denom::character varying as denom,
    'volume_daily'::character varying as chart_type,
    cast(extract(epoch from datetime) as integer) as point_index,
    volume_in_usd::numeric as point_value
FROM
    tokens_dataset
WHERE
    datetime > request_timestamp - make_interval(hours => 24/*day*/)


$function$;
