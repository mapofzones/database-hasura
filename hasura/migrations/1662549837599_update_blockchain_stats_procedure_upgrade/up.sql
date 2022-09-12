CREATE OR REPLACE PROCEDURE public.update_blockchain_stats(request_timestamp timestamp, period_in_hours integer)
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.blockchain_stats;

INSERT INTO flat.blockchain_stats
SELECT
    blockchain,
    timestamp as timeframe,
    txs,
    txs_diff,
    ibc_active_addresses_cnt,
    ibc_active_addresses_cnt_diff,
    active_addresses_cnt,
    active_addresses_cnt_diff,
    ibc_active_addresses_percent
FROM 
    get_blockchain_stats(request_timestamp, period_in_hours);

$$;
