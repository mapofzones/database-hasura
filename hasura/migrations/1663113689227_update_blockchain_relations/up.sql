CREATE OR REPLACE PROCEDURE public.update_blockchain_relations(request_timestamp timestamp without time zone, period_in_hours integer)
 LANGUAGE sql
AS $$
    
-- TRUNCATE TABLE flat.blockchain_relations;

INSERT INTO flat.blockchain_relations
SELECT
    blockchain_source,
    blockchain_target,
    timeframe,
    ibc_transfers,
    ibc_transfers_diff,
    ibc_transfers_pending,
    ibc_transfers_failed,
    ibc_cashflow,
    ibc_cashflow_diff,
    ibc_cashflow_pending,
    source_to_target_ibc_transfers,
    source_to_target_ibc_cashflow,
    target_to_source_ibc_transfers,
    target_to_source_ibc_cashflow,
    is_mainnet
FROM
    get_blockchain_relations(request_timestamp, period_in_hours);

$$;
