CREATE OR REPLACE FUNCTION public.get_total_tf_switched_charts_trading_volume()
 RETURNS SETOF temp_t_get_total_tf_switched_charts
 LANGUAGE sql
 STABLE
AS $function$

SELECT
    true as is_mainnet,
    24 as timeframe,
    'trading_volume' as chart_type,
    point_index,
    sum(point_value)::NUMERIC as point_value
FROM
    flat.token_charts
WHERE
    chart_type = 'volume_daily'
GROUP BY
    point_index

$function$;
