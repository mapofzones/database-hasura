CREATE OR REPLACE PROCEDURE public.update_blockchain_tf_charts(request_timestamp timestamp without time zone)
 LANGUAGE sql
AS $$
    
-- TRUNCATE TABLE flat.blockchain_tf_charts;

INSERT INTO flat.blockchain_tf_charts
SELECT
    btc.blockchain,
    btc.timeframe,
    btc.chart_type,
    btc.point_index,
    btc.point_value
FROM
    public.get_blockchain_tf_charts(request_timestamp) as btc;

$$;
