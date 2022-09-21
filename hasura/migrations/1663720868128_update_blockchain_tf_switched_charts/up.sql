CREATE OR REPLACE PROCEDURE public.update_blockchain_tf_switched_charts(request_timestamp timestamp without time zone)
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.blockchain_tf_switched_charts;

INSERT INTO flat.blockchain_tf_switched_charts
SELECT
    blockchain,
    is_mainnet,
    timeframe,
    chart_type,
    point_index,
    point_value
FROM
    public.get_blockchain_tf_switched_charts(request_timestamp)

$$;
