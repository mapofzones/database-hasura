CREATE OR REPLACE PROCEDURE public.update_blockchain_switched_stats()
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.blockchain_switched_stats;

INSERT INTO flat.blockchain_switched_stats
SELECT
    blockchain,
    is_mainnet,
    timeframe,
    channels_cnt,
    ibc_peers,
    txs_rating,
    txs_rating_diff,
    ibc_active_addresses_cnt_rating,
    ibc_active_addresses_cnt_rating_diff,
    ibc_cashflow,
    ibc_cashflow_diff,
    ibc_cashflow_rating,
    ibc_cashflow_rating_diff,
    ibc_cashflow_pending,
    ibc_cashflow_in,
    ibc_cashflow_in_diff,
    ibc_cashflow_in_rating,
    ibc_cashflow_in_rating_diff,
    ibc_cashflow_in_percent,
    ibc_cashflow_in_pending,
    ibc_cashflow_out,
    ibc_cashflow_out_diff,
    ibc_cashflow_out_rating,
    ibc_cashflow_out_rating_diff,
    ibc_cashflow_out_percent,
    ibc_cashflow_out_pending,
    ibc_transfers,
    ibc_transfers_diff,
    ibc_transfers_rating,
    ibc_transfers_rating_diff,
    ibc_transfers_pending,
    ibc_transfers_success_rate,
    active_addresses_cnt_rating,
    active_addresses_cnt_rating_diff
FROM 
    get_blockchain_switched_stats();

$$;
