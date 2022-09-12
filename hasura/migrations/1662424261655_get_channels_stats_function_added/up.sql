DROP FUNCTION IF EXISTS public.get_channels_stats();

DROP TYPE IF EXISTS public.temp_t_get_channels_stats;

CREATE TYPE public.temp_t_get_channels_stats as (
    blockchain character varying,
    timeframe integer,
    channel_id character varying,
    client_id character varying,
    connection_id character varying,
    is_channel_open bool,
    counterparty_blockchain character varying,
    counterparty_channel_id character varying,
    ibc_transfers integer,
    ibc_transfers_diff integer,
    ibc_transfers_pending integer,
    ibc_transfers_failed integer,
    ibc_transfers_failed_diff integer,

    ibc_transfers_success_rate numeric,
    ibc_transfers_success_rate_diff numeric,
    ibc_cashflow_in bigint,
    ibc_cashflow_in_diff bigint,
    ibc_cashflow_in_pending bigint,
    ibc_cashflow_out bigint,
    ibc_cashflow_out_diff bigint,
    ibc_cashflow_out_pending bigint,
    ibc_cashflow bigint,
    ibc_cashflow_diff bigint,
    ibc_cashflow_pending bigint
);

CREATE OR REPLACE FUNCTION public.get_channels_stats(request_timestamp timestamp, period_in_hours integer)
 RETURNS SETOF temp_t_get_channels_stats
 LANGUAGE sql
 STABLE
AS $function$

with hourly_channels_stats_current as (
  SELECT
    one.blockchain,
    one.channel_id,
    one.timestamp,

    ibc_clients.client_id as client_id,
    ibc_connections.connection_id as connection_id,
    ibc_channels.is_opened as is_channel_open,
    ibc_clients.chain_id as counterparty_blockchain,
    ibc_channels.counterparty_channel_id as counterparty_channel_id,

    one.ibc_transfers_failed + coalesce(two.ibc_transfers_failed, 0) as ibc_transfers_failed,
    one.ibc_cashflow_in,
    one.ibc_transfers_in,
    coalesce(two.ibc_cashflow_in, 0) as ibc_cashflow_out,
    coalesce(two.ibc_transfers_in, 0) as ibc_transfers_out,
    one.ibc_cashflow_out as ibc_cashflow_out_internal,
    one.ibc_transfers_out as ibc_transfers_out_internal,
    coalesce(two.ibc_cashflow_out, 0) as ibc_cashflow_in_external,
    coalesce(two.ibc_transfers_out, 0) as ibc_transfers_in_external
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
  LEFT JOIN intermediate.channels_hourly_stats as two ON
    ibc_clients.chain_id = two.blockchain
    and ibc_channels.counterparty_channel_id = two.channel_id
    and one.timestamp = two.timestamp
  WHERE
    one.timestamp > request_timestamp - make_interval(hours => period_in_hours)
    and one.timestamp <= request_timestamp
)
, channels_stats_current as (
  SELECT
    blockchain,
    channel_id,
    client_id,
    connection_id,
    is_channel_open,
    counterparty_blockchain,
    counterparty_channel_id,

    sum(ibc_transfers_failed) as ibc_transfers_failed,
    sum(ibc_cashflow_in) as ibc_cashflow_in,
    sum(ibc_transfers_in) as ibc_transfers_in,
    sum(ibc_cashflow_out) as ibc_cashflow_out,
    sum(ibc_transfers_out) as ibc_transfers_out,
    sum(ibc_cashflow_out_internal) as ibc_cashflow_out_internal,
    sum(ibc_transfers_out_internal) as ibc_transfers_out_internal,
    sum(ibc_cashflow_in_external) as ibc_cashflow_in_external,
    sum(ibc_transfers_in_external) as ibc_transfers_in_external
  FROM
    hourly_channels_stats_current
  GROUP BY
    blockchain,
    channel_id,
    client_id,
    connection_id,
    is_channel_open,
    counterparty_blockchain,
    counterparty_channel_id
)
, channels_stats as (
  SELECT
    blockchain,
    channel_id,
    client_id,
    connection_id,
    is_channel_open,
    counterparty_blockchain,
    counterparty_channel_id,

    ibc_transfers_failed,
    ibc_cashflow_in,
    ibc_transfers_in,
    ibc_cashflow_out,
    ibc_transfers_out,
    CASE
      WHEN ibc_cashflow_out_internal - ibc_cashflow_out < 0 THEN 0
      ELSE ibc_cashflow_out_internal - ibc_cashflow_out
    END as ibc_cashflow_out_pending,
    CASE
      WHEN ibc_transfers_out_internal - ibc_transfers_out < 0 THEN 0
      ELSE ibc_transfers_out_internal - ibc_transfers_out
    END as ibc_transfers_out_pending,
    CASE
      WHEN ibc_cashflow_in_external - ibc_cashflow_in < 0 THEN 0
      ELSE ibc_cashflow_in_external - ibc_cashflow_in
    END as ibc_cashflow_in_pending,
    CASE
      WHEN ibc_transfers_in_external - ibc_transfers_in < 0 THEN 0
      ELSE ibc_transfers_in_external - ibc_transfers_in
    END as ibc_transfers_in_pending
  FROM
    channels_stats_current
)
, hourly_channels_stats_previous as (
  SELECT
    one.blockchain,
    one.channel_id,
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
  LEFT JOIN intermediate.channels_hourly_stats as two ON
    ibc_clients.chain_id = two.blockchain
    and ibc_channels.counterparty_channel_id = two.channel_id
    and one.timestamp = two.timestamp
  WHERE
    one.timestamp > request_timestamp - make_interval(hours => 2*period_in_hours)
    and one.timestamp <= request_timestamp - make_interval(hours => period_in_hours)
)
, channels_stats_previous as (
  SELECT
    blockchain,
    channel_id,

    sum(ibc_transfers_failed) as ibc_transfers_failed,
    sum(ibc_cashflow_in) as ibc_cashflow_in,
    sum(ibc_transfers_in) as ibc_transfers_in,
    sum(ibc_cashflow_out) as ibc_cashflow_out,
    sum(ibc_transfers_out) as ibc_transfers_out
  FROM
    hourly_channels_stats_previous
  GROUP BY
    blockchain,
    channel_id
)

SELECT
    channels_stats.blockchain,
    period_in_hours as timeframe,
    channels_stats.channel_id,
    client_id,
    connection_id,
    is_channel_open,
    counterparty_blockchain,
    counterparty_channel_id,

    (channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out)::integer as ibc_transfers,
    (channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out - channels_stats_previous.ibc_transfers_in - channels_stats_previous.ibc_transfers_out)::integer as ibc_transfers_diff,
    (channels_stats.ibc_transfers_in_pending + channels_stats.ibc_transfers_out_pending)::integer as ibc_transfers_pending,
    (channels_stats.ibc_transfers_failed)::integer as ibc_transfers_failed,
    (channels_stats.ibc_transfers_failed - channels_stats_previous.ibc_transfers_failed)::integer as ibc_transfers_failed_diff,
    (((channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out)::NUMERIC / coalesce(nullif(channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out + channels_stats.ibc_transfers_failed, 0), 1)::NUMERIC) * 100.0)::NUMERIC as ibc_transfers_success_rate,

    ((((channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out)::NUMERIC / coalesce(nullif(channels_stats.ibc_transfers_in + channels_stats.ibc_transfers_out + channels_stats.ibc_transfers_failed, 0), 1)::NUMERIC) * 100.0)::NUMERIC -
      (((channels_stats_previous.ibc_transfers_in + channels_stats_previous.ibc_transfers_out)::NUMERIC / coalesce(nullif(channels_stats_previous.ibc_transfers_in + channels_stats_previous.ibc_transfers_out + channels_stats_previous.ibc_transfers_failed, 0), 1)::NUMERIC) * 100.0))::NUMERIC
        as ibc_transfers_success_rate_diff,

    channels_stats.ibc_cashflow_in::bigint,
    (channels_stats.ibc_cashflow_in - channels_stats_previous.ibc_cashflow_in)::bigint as ibc_cashflow_in_diff,
    channels_stats.ibc_cashflow_in_pending::bigint,
    channels_stats.ibc_cashflow_out::bigint,
    (channels_stats.ibc_cashflow_out - channels_stats_previous.ibc_cashflow_out)::bigint as ibc_cashflow_out_diff,
    channels_stats.ibc_cashflow_out_pending::bigint,
    (channels_stats.ibc_cashflow_in + channels_stats.ibc_cashflow_out)::bigint as ibc_cashflow,
    (channels_stats.ibc_cashflow_in + channels_stats.ibc_cashflow_out - channels_stats_previous.ibc_cashflow_in - channels_stats_previous.ibc_cashflow_out)::bigint as ibc_cashflow_diff,
    (channels_stats.ibc_cashflow_in_pending + channels_stats.ibc_cashflow_out_pending)::bigint as ibc_cashflow_pending
FROM
  channels_stats
LEFT JOIN channels_stats_previous ON
  channels_stats_previous.blockchain = channels_stats.blockchain
  and channels_stats_previous.channel_id = channels_stats.channel_id

$function$;
