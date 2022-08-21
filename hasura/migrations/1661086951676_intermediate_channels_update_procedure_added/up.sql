CREATE OR REPLACE PROCEDURE public.update_channels_hourly_stats(request_timestamp timestamp, period_in_hours integer)
 LANGUAGE sql
AS $$

TRUNCATE TABLE intermediate.channels_hourly_stats;

INSERT INTO intermediate.channels_hourly_stats
SELECT 
    blockchain,
    channel_id,
    timestamp,
    ibc_transfers_failed,
    ibc_cashflow_in,
    ibc_cashflow_out,
    ibc_transfers_in,
    ibc_transfers_out
FROM
    get_channels_hourly_stats(request_timestamp, period_in_hours);

$$;
