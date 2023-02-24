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
--   RIGHT JOIN flat.blockchain_switched_stats as allowed_zones ON
--     one.blockchain = allowed_zones.blockchain
  WHERE
    one.timestamp >= date_trunc('day', request_timestamp) - make_interval(hours => 720) + make_interval(hours => 24)
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
    point_index >= cast(extract(epoch from (date_trunc('day', request_timestamp) - make_interval(hours => 168))) as integer)
)
, hourly_stats_current_day as (
  SELECT
    blockchain,
    cast(extract(epoch from date_trunc('hour', timestamp)) as integer) as point_index,
    sum(ibc_transfers_failed) as ibc_transfers_failed,
    sum(ibc_cashflow_in) as ibc_cashflow_in,
    sum(ibc_transfers_in) as ibc_transfers_in,
    sum(ibc_cashflow_out) as ibc_cashflow_out,
    sum(ibc_transfers_out) as ibc_transfers_out
  FROM
    hourly_stats_current_month
  WHERE
    timestamp >= date_trunc('hour', request_timestamp) - make_interval(hours => (24))
  GROUP BY
    blockchain,
    date_trunc('hour', timestamp)
)

-- start daily cashflow calcs
, cashflow_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'cashflow_general' as chart_type,
    point_index,
    (ibc_cashflow_in + ibc_cashflow_out)::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
, cashflow_in_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'cashflow_in' as chart_type,
    point_index,
    ibc_cashflow_in::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
, cashflow_out_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'cashflow_out' as chart_type,
    point_index,
    ibc_cashflow_out::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
-- end daily cashflow calcs

-- start daily transfers calcs
, transfers_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'transfers_general' as chart_type,
    point_index,
    (ibc_transfers_in + ibc_transfers_out)::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
, transfers_in_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'transfers_in' as chart_type,
    point_index,
    (ibc_transfers_in)::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
, transfers_out_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'transfers_out' as chart_type,
    point_index,
    (ibc_transfers_out)::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
, transfers_failed_day as (
  SELECT
    blockchain,
    true as is_mainnet,
    24 as timeframe,
    'transfers_failed' as chart_type,
    point_index,
    (ibc_transfers_failed)::NUMERIC as point_value
  FROM
    hourly_stats_current_day
)
-- end daily transfers calcs

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
  cashflow_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_in_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  cashflow_out_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_in_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_out_day
UNION ALL
SELECT
  blockchain,
  is_mainnet,
  timeframe,
  chart_type,
  point_index,
  point_value
FROM
  transfers_failed_day
UNION ALL
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
