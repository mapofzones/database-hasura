CREATE OR REPLACE PROCEDURE public.update_token_charts(request_timestamp timestamp without time zone)
 LANGUAGE sql
AS $$
    
-- TRUNCATE TABLE flat.token_charts;

INSERT INTO flat.token_charts
SELECT
    tc.blockchain,
    tc.denom,
    tc.chart_type,
    tc.point_index,
    tc.point_value
FROM
    public.get_token_charts(request_timestamp) as tc;
    
$$;
