CREATE OR REPLACE FUNCTION public.get_blockchain_tf_charts(request_timestamp timestamp)
 RETURNS SETOF temp_t_get_blockchain_tf_charts
 LANGUAGE sql
 STABLE
AS $function$

SELECT
    network_id as blockchain,
    24 as timeframe,
    'txs' as chart_type,
    cast(extract(epoch from timestamp) as integer) as point_index,
    txs::NUMERIC as point_value
FROM
    intermediate.blockchains_hourly_stats
WHERE
    timestamp > request_timestamp - make_interval(hours => 24/*day*/)
UNION ALL
SELECT
    network_id as blockchain,
    168 as timeframe,
    'txs' as chart_type,
    cast(extract(epoch from timestamp) as integer) as point_index,
    txs::NUMERIC as point_value
FROM
    intermediate.blockchains_hourly_stats
WHERE
    timestamp > request_timestamp - make_interval(hours => 168/*week*/)
UNION ALL
SELECT
    network_id as blockchain,
    720 as timeframe,
    'txs' as chart_type,
    cast(extract(epoch from timestamp) as integer) as point_index,
    txs::NUMERIC as point_value
FROM
    intermediate.blockchains_hourly_stats
WHERE
    timestamp > request_timestamp - make_interval(hours => 720/*month*/)

$function$;
