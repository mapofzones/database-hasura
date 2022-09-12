CREATE OR REPLACE PROCEDURE public.update_channels_stats(request_timestamp timestamp, period_in_hours integer)
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.channels_stats;

INSERT INTO flat.channels_stats
SELECT
    blockchain,
    timeframe,
    channel_id,
    client_id,
    connection_id,
    is_channel_open,
    counterparty_blockchain,
    counterparty_channel_id,

    ibc_transfers,
    ibc_transfers_diff,
    ibc_transfers_pending,
    ibc_transfers_failed,
    ibc_transfers_failed_diff,
    ibc_transfers_success_rate,

    ibc_transfers_success_rate_diff,

    ibc_cashflow_in,
    ibc_cashflow_in_diff,
    ibc_cashflow_in_pending,
    ibc_cashflow_out,
    ibc_cashflow_out_diff,
    ibc_cashflow_out_pending,
    ibc_cashflow,
    ibc_cashflow_diff,
    ibc_cashflow_pending
FROM 
    public.get_channels_stats(request_timestamp, period_in_hours);

$$;
