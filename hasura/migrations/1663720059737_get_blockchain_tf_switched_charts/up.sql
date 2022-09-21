DROP FUNCTION IF EXISTS public.get_blockchain_tf_switched_charts(request_timestamp timestamp);

DROP TYPE IF EXISTS public.temp_t_get_blockchain_tf_switched_charts;

CREATE TYPE public.temp_t_get_blockchain_tf_switched_charts as (
    blockchain character varying,
    is_mainnet boolean,
    timeframe integer,
    chart_type character varying,
    point_index integer,
    point_value numeric
);

CREATE OR REPLACE FUNCTION public.get_blockchain_tf_switched_charts(request_timestamp timestamp)
 RETURNS SETOF temp_t_get_blockchain_tf_switched_charts
 LANGUAGE sql
 STABLE
AS $function$

SELECT
    chs.blockchain,
    true as is_mainnet,
    24 as timeframe,
    'transfers' as chart_type,
    cast(extract(epoch from chs.timestamp) as integer) as point_index,
    sum(chs.ibc_transfers_in)::NUMERIC as point_value
FROM
    intermediate.channels_hourly_stats as chs
RIGHT JOIN flat.blockchain_switched_stats as bss ON bss.blockchain = chs.blockchain
WHERE
    chs.timestamp > request_timestamp - make_interval(hours => 24/*day*/)
GROUP BY
    chs.blockchain,
    cast(extract(epoch from chs.timestamp) as integer)
UNION ALL
SELECT
    chs.blockchain,
    true as is_mainnet,
    168 as timeframe,
    'transfers' as chart_type,
    cast(extract(epoch from chs.timestamp) as integer) as point_index,
    sum(chs.ibc_transfers_in)::NUMERIC as point_value
FROM
    intermediate.channels_hourly_stats as chs
RIGHT JOIN flat.blockchain_switched_stats as bss ON bss.blockchain = chs.blockchain
WHERE
    chs.timestamp > request_timestamp - make_interval(hours => 168/*week*/)
GROUP BY
    chs.blockchain,
    cast(extract(epoch from chs.timestamp) as integer)
UNION ALL
SELECT
    chs.blockchain,
    true as is_mainnet,
    720 as timeframe,
    'transfers' as chart_type,
    cast(extract(epoch from chs.timestamp) as integer) as point_index,
    sum(chs.ibc_transfers_in)::NUMERIC as point_value
FROM
    intermediate.channels_hourly_stats as chs
RIGHT JOIN flat.blockchain_switched_stats as bss ON bss.blockchain = chs.blockchain
WHERE
    chs.timestamp > request_timestamp - make_interval(hours => 720/*week*/)
GROUP BY
    chs.blockchain,
    cast(extract(epoch from chs.timestamp) as integer)

$function$;
