CREATE OR REPLACE PROCEDURE public.update_total_tf_switched_charts_trading_volume()
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.total_tf_switched_charts;

INSERT INTO flat.total_tf_switched_charts
SELECT
    is_mainnet,
    timeframe,
    chart_type,
    point_index,
    point_value
FROM
    get_total_tf_switched_charts_trading_volume()

$$;
