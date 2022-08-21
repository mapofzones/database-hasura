CREATE OR REPLACE PROCEDURE public.update_blockchains_hourly_stats(request_timestamp timestamp, period_in_hours integer)
 LANGUAGE sql
AS $$

TRUNCATE TABLE intermediate.blockchains_hourly_stats;

INSERT INTO intermediate.blockchains_hourly_stats
SELECT 
    network_id,
    timestamp,
    txs
FROM 
    get_blockchains_hourly_stats(request_timestamp, period_in_hours);

$$;
