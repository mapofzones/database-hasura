CREATE OR REPLACE FUNCTION public.get_blockchain_tf_switched_charts_recalc(request_timestamp timestamp)
 RETURNS SETOF temp_t_get_blockchain_tf_switched_charts
 LANGUAGE sql
 STABLE
AS $function$

with hourly_stats_current_month as (
  SELECT
    one.blockchain,
    one.timestamp,
    one.ibc_transfers_failed + coalesce(two.ibc_transfers_failed, 0) as ibc_transfers_failed,
    one.ibc_cashflow_in,
    one.ibc_transfers_in,
    coalesce(two.ibc_cashflow_in, 0) as ibc_cashflow_out,
    coalesce(two.ibc_transfers_in, 0) as ibc_transfers_out
  FROM
    intermediate.channels_hourly_stats as one
  LEFT JOIN public.ibc_channels as ibc_channels ON
    one.blockchain = ibc_channels.zone
    and one.channel_id = ibc_channels.channel_id
  LEFT JOIN public.ibc_connections as ibc_connections ON
    ibc_channels.zone = ibc_connections.zone
    and ibc_channels.connection_id = ibc_connections.connection_id
  LEFT JOIN public.ibc_clients as ibc_clients ON
    ibc_clients.zone = ibc_connections.zone
    and ibc_clients.client_id = ibc_connections.client_id
  LEFT JOIN public.ibc_channels as ibc_channels_counterparty ON
    ibc_clients.chain_id = ibc_channels_counterparty.zone
    and ibc_channels.counterparty_channel_id = ibc_channels_counterparty.channel_id
    and ibc_channels.channel_id = ibc_channels_counterparty.counterparty_channel_id
  LEFT JOIN public.ibc_connections as ibc_connections_counterparty ON
    ibc_channels_counterparty.zone = ibc_connections_counterparty.zone
    and ibc_channels_counterparty.connection_id = ibc_connections_counterparty.connection_id
  LEFT JOIN public.ibc_clients as ibc_clients_counterparty ON
    ibc_clients_counterparty.zone = ibc_connections_counterparty.zone
    and ibc_clients_counterparty.client_id = ibc_connections_counterparty.client_id
    and  ibc_clients_counterparty.chain_id = ibc_clients.zone
  LEFT JOIN intermediate.channels_hourly_stats as two ON
    ibc_clients_counterparty.zone = two.blockchain
    and ibc_channels_counterparty.channel_id = two.channel_id
    and one.timestamp = two.timestamp
  LEFT JOIN public.zones as zones ON
    ibc_clients.chain_id = zones.chain_id
  WHERE
    one.timestamp > date_trunc('day', request_timestamp) + make_interval(hours => 24)/*remove partial first day*/ - make_interval(hours => 720)
    and one.timestamp <= request_timestamp
    and zones.is_mainnet = true
)
, daily_stats_current_month as (
  SELECT
    blockchain,
    cast(extract(epoch from date_trunc('day', timestamp)) as integer) as point_index,
    sum(ibc_transfers_failed) as ibc_transfers_failed,
    sum(ibc_cashflow_in) as ibc_cashflow_in,
    sum(ibc_transfers_in) as ibc_transfers_in,
    sum(ibc_cashflow_out) as ibc_cashflow_out,
    sum(ibc_transfers_out) as ibc_transfers_out
  FROM
    hourly_stats_current_month
  GROUP BY
    blockchain,
    date_trunc('day', timestamp)
)
, daily_stats_current_week as (
  SELECT
    blockchain,
    point_index,
    ibc_transfers_failed,
    ibc_cashflow_in,
    ibc_transfers_in,
    ibc_cashflow_out,
    ibc_transfers_out
  FROM
    daily_stats_current_month
  WHERE
    point_index >= cast(extract(epoch from (date_trunc('day', request_timestamp) + make_interval(hours => 24)/*remove partial first day*/ - make_interval(hours => 168))) as integer)
)
, daily_stats_current_two_weeks as (
  SELECT
    blockchain,
    point_index,
    ibc_transfers_failed,
    ibc_cashflow_in,
    ibc_transfers_in,
    ibc_cashflow_out,
    ibc_transfers_out
  FROM
    daily_stats_current_month
  WHERE
    point_index >= cast(extract(epoch from (date_trunc('day', request_timestamp) + make_interval(hours => 24)/*remove partial first day*/ - make_interval(hours => (168*2)))) as integer)
)

-- start weekly cashflow calcs
, cashflow_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'cashflow_general' as chart_type,
    point_index,
    (ibc_cashflow_in + ibc_cashflow_out)::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
, cashflow_in_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'cashflow_in' as chart_type,
    point_index,
    ibc_cashflow_in::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
, cashflow_out_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'cashflow_out' as chart_type,
    point_index,
    ibc_cashflow_out::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
-- end weekly cashflow calcs

-- start weekly transfers calcs
, transfers_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'transfers_general' as chart_type,
    point_index,
    (ibc_transfers_in + ibc_transfers_out)::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
, transfers_in_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'transfers_in' as chart_type,
    point_index,
    (ibc_transfers_in)::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
, transfers_out_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'transfers_out' as chart_type,
    point_index,
    (ibc_transfers_out)::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
, transfers_failed_week as (
  SELECT
    blockchain,
    true as is_mainnet,
    168 as timeframe,
    'transfers_failed' as chart_type,
    point_index,
    (ibc_transfers_failed)::NUMERIC as point_value
  FROM
    daily_stats_current_week
)
-- end weekly transfers calcs

-- -- start two weeks cashflow calcs
-- , cashflow_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'cashflow_general' as chart_type,
--     point_index,
--     (ibc_cashflow_in + ibc_cashflow_out)::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- , cashflow_in_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'cashflow_in' as chart_type,
--     point_index,
--     ibc_cashflow_in::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- , cashflow_out_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'cashflow_out' as chart_type,
--     point_index,
--     ibc_cashflow_out::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- -- end two weeks cashflow calcs
--
-- -- start two weeks transfers calcs
-- , transfers_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'transfers_general' as chart_type,
--     point_index,
--     (ibc_transfers_in + ibc_transfers_out)::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- , transfers_in_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'transfers_in' as chart_type,
--     point_index,
--     (ibc_transfers_in)::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- , transfers_out_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'transfers_out' as chart_type,
--     point_index,
--     (ibc_transfers_out)::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- , transfers_failed_two_weeks as (
--   SELECT
--     blockchain,
--     true as is_mainnet,
--     336 as timeframe,
--     'transfers_failed' as chart_type,
--     point_index,
--     (ibc_transfers_failed)::NUMERIC as point_value
--   FROM
--     daily_stats_current_two_weeks
-- )
-- -- end two weeks transfers calcs

-- start monthly cashflow calcs
, cashflow_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'cashflow_general' as chart_type,
    point_index,
    (ibc_cashflow_in + ibc_cashflow_out)::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
, cashflow_in_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'cashflow_in' as chart_type,
    point_index,
    ibc_cashflow_in::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
, cashflow_out_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'cashflow_out' as chart_type,
    point_index,
    ibc_cashflow_out::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
-- end monthly cashflow calcs

-- start monthly transfers calcs
, transfers_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'transfers_general' as chart_type,
    point_index,
    (ibc_transfers_in + ibc_transfers_out)::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
, transfers_in_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'transfers_in' as chart_type,
    point_index,
    (ibc_transfers_in)::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
, transfers_out_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'transfers_out' as chart_type,
    point_index,
    (ibc_transfers_out)::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
, transfers_failed_month as (
  SELECT
    blockchain,
    true as is_mainnet,
    720 as timeframe,
    'transfers_failed' as chart_type,
    point_index,
    (ibc_transfers_failed)::NUMERIC as point_value
  FROM
    daily_stats_current_month
)
-- end monthly transfers calcs

-- start UNION all subqueries
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_in_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_out_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_in_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_out_week
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_failed_week
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   cashflow_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   cashflow_in_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   cashflow_out_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   transfers_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   transfers_in_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   transfers_out_two_weeks
-- UNION ALL
-- SELECT
--   blockchain,
--   is_mainnet,
--   timeframe,
--   chart_type,
--   point_index,
--   point_value
-- FROM
--   transfers_failed_two_weeks
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_in_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_out_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_in_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_out_month
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_failed_month
-- end UNION all subqueries

$function$;

CREATE OR REPLACE PROCEDURE public.update_blockchain_tf_switched_charts_recalc(request_timestamp timestamp without time zone)
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
    get_blockchain_tf_switched_charts_recalc(request_timestamp)

$$;

CREATE OR REPLACE PROCEDURE public.update_flat_tables_calcs(request_timestamp timestamp)
 LANGUAGE sql
AS $$

-- truncate intermediate
TRUNCATE TABLE intermediate.blockchains_hourly_stats;
TRUNCATE TABLE intermediate.channels_hourly_stats;

-- delete flat
DELETE FROM flat.blockchain_relations;
DELETE FROM flat.blockchain_tf_charts;
DELETE FROM flat.blockchain_tf_switched_charts;
DELETE FROM flat.blockchain_switched_stats;
DELETE FROM flat.blockchain_stats;
DELETE FROM flat.channels_stats;
DELETE FROM flat.token_charts;
UPDATE flat.blockchains SET base_token = NULL;
DELETE FROM flat.tokens;
DELETE FROM flat.blockchains;
DELETE FROM flat.total_tf_switched_charts;

-- intermediate
CALL
  update_blockchains_hourly_stats(request_timestamp, 720);
CALL
  update_channels_hourly_stats(request_timestamp, 720);

-- flat
CALL
  update_blockchains();

CALL
  update_blockchain_stats(request_timestamp, 24);
CALL
  update_blockchain_stats(request_timestamp, 168);
CALL
  update_blockchain_stats(request_timestamp, 720);

CALL
  update_channels_stats(request_timestamp, 24);
CALL
  update_channels_stats(request_timestamp, 168);
CALL
  update_channels_stats(request_timestamp, 720);

CALL
    update_blockchain_relations(request_timestamp, 24);
CALL
    update_blockchain_relations(request_timestamp, 168);
CALL
    update_blockchain_relations(request_timestamp, 720);

CALL
    update_tokens();

CALL
    update_blockchains_extention();

CALL
    update_blockchain_switched_stats();

CALL
    update_token_charts(request_timestamp);


CALL
    update_blockchain_tf_charts(request_timestamp);
CALL
    update_blockchain_tf_switched_charts(request_timestamp);
CALL
    update_blockchain_tf_switched_charts_cashflow(request_timestamp);
CALL
    update_total_tf_switched_charts_cashflow(request_timestamp);
CALL
    update_total_tf_switched_charts_trading_volume();
CALL
    update_blockchain_tf_switched_charts_recalc(request_timestamp);

$$;
