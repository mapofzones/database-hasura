DROP FUNCTION IF EXISTS public.get_blockchain_relations(request_timestamp timestamp without time zone, period_in_hours integer);

DROP TYPE IF EXISTS public.temp_t_get_blockchain_relations;

CREATE TYPE public.temp_t_get_blockchain_relations as (
    blockchain_source character varying,
    blockchain_target character varying,
    is_mainnet bool,
    timeframe integer,
    ibc_transfers integer,
    ibc_transfers_diff integer,
    ibc_transfers_pending integer,
    ibc_transfers_failed integer,
    ibc_cashflow bigint,
    ibc_cashflow_diff bigint,
    ibc_cashflow_pending bigint,
    source_to_target_ibc_transfers integer,
    source_to_target_ibc_cashflow bigint,
    target_to_source_ibc_transfers integer,
    target_to_source_ibc_cashflow bigint
);

CREATE OR REPLACE FUNCTION public.get_blockchain_relations(request_timestamp timestamp without time zone, period_in_hours integer)
RETURNS SETOF temp_t_get_blockchain_relations
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

, both_sides_channels_stats as (
    SELECT
        channels_stats.blockchain  as blockchain_source,
        counterparty_blockchain as blockchain_target,
        period_in_hours as timeframe,

        (coalesce(channels_stats.ibc_transfers_in, 0) + coalesce(channels_stats.ibc_transfers_out, 0))::integer as ibc_transfers,
        (coalesce(channels_stats.ibc_transfers_in, 0) + coalesce(channels_stats.ibc_transfers_out, 0) -
            coalesce(channels_stats_previous.ibc_transfers_in, 0) - coalesce(channels_stats_previous.ibc_transfers_out, 0))::integer as ibc_transfers_diff,
        (coalesce(channels_stats.ibc_transfers_in_pending, 0) + coalesce(channels_stats.ibc_transfers_out_pending, 0))::integer as ibc_transfers_pending,
        coalesce(channels_stats.ibc_transfers_failed, 0)::integer as ibc_transfers_failed,

        (coalesce(channels_stats.ibc_cashflow_in, 0) + coalesce(channels_stats.ibc_cashflow_out, 0))::bigint as ibc_cashflow,
        (coalesce(channels_stats.ibc_cashflow_in, 0) + coalesce(channels_stats.ibc_cashflow_out, 0) - coalesce(channels_stats_previous.ibc_cashflow_in, 0) - coalesce(channels_stats_previous.ibc_cashflow_out, 0))::bigint as ibc_cashflow_diff,
        (coalesce(channels_stats.ibc_cashflow_in_pending, 0) + coalesce(channels_stats.ibc_cashflow_out_pending, 0))::bigint as ibc_cashflow_pending,

        coalesce(channels_stats.ibc_transfers_out, 0) as source_to_target_ibc_transfers,
        coalesce(channels_stats.ibc_cashflow_out, 0) as source_to_target_ibc_cashflow,
        coalesce(channels_stats.ibc_transfers_in, 0) as target_to_source_ibc_transfers,
        coalesce(channels_stats.ibc_cashflow_in, 0) as target_to_source_ibc_cashflow
    FROM
      channels_stats
    LEFT JOIN channels_stats_previous ON
      channels_stats_previous.blockchain = channels_stats.blockchain
      and channels_stats_previous.channel_id = channels_stats.channel_id
)
, both_sides_grouped_channels_stats as (
    SELECT
        blockchain_source,
        blockchain_target,
        true as is_mainnet,
        timeframe,
        sum(ibc_transfers) as ibc_transfers,
        sum(ibc_transfers_diff) as ibc_transfers_diff,
        sum(ibc_transfers_pending) as ibc_transfers_pending,
        sum(ibc_transfers_failed) as ibc_transfers_failed,
        sum(ibc_cashflow) as ibc_cashflow,
        sum(ibc_cashflow_diff) as ibc_cashflow_diff,
        sum(ibc_cashflow_pending) as ibc_cashflow_pending,
        sum(source_to_target_ibc_transfers) as source_to_target_ibc_transfers,
        sum(source_to_target_ibc_cashflow) as source_to_target_ibc_cashflow,
        sum(target_to_source_ibc_transfers) as target_to_source_ibc_transfers,
        sum(target_to_source_ibc_cashflow) as target_to_source_ibc_cashflow
    FROM
        both_sides_channels_stats as both_sides
    LEFT JOIN public.zones as chain ON both_sides.blockchain_source = chain.chain_id
    LEFT JOIN public.zones as chain_counterparty ON both_sides.blockchain_target = chain_counterparty.chain_id
    WHERE
        chain.is_mainnet = true
        and chain_counterparty.is_mainnet = true
    GROUP BY
        blockchain_source,
        blockchain_target,
        timeframe
)
, doubled_stats as (
    SELECT
        coalesce(one.blockchain_source, two.blockchain_target) as blockchain_source,
        coalesce(one.blockchain_target, two.blockchain_source) as blockchain_target,
        true as is_mainnet,
        coalesce(one.timeframe, two.timeframe) as timeframe,
        coalesce(one.ibc_transfers, two.ibc_transfers) as ibc_transfers,
        coalesce(one.ibc_transfers_diff, two.ibc_transfers_diff) as ibc_transfers_diff,
        coalesce(one.ibc_transfers_pending, two.ibc_transfers_pending) as ibc_transfers_pending,
        coalesce(one.ibc_transfers_failed, two.ibc_transfers_failed) as ibc_transfers_failed,
        coalesce(one.ibc_cashflow, two.ibc_cashflow) as ibc_cashflow,
        coalesce(one.ibc_cashflow_diff, two.ibc_cashflow_diff) as ibc_cashflow_diff,
        coalesce(one.ibc_cashflow_pending, two.ibc_cashflow_pending) as ibc_cashflow_pending,
        coalesce(one.source_to_target_ibc_transfers, two.target_to_source_ibc_transfers) as source_to_target_ibc_transfers,
        coalesce(one.source_to_target_ibc_cashflow, two.target_to_source_ibc_cashflow) as source_to_target_ibc_cashflow,
        coalesce(one.target_to_source_ibc_transfers, two.source_to_target_ibc_transfers) as target_to_source_ibc_transfers,
        coalesce(one.target_to_source_ibc_cashflow, two.source_to_target_ibc_cashflow) as target_to_source_ibc_cashflow
    FROM
        both_sides_grouped_channels_stats as one
    FULL OUTER JOIN both_sides_grouped_channels_stats as two
        ON one.blockchain_source = two.blockchain_target and one.blockchain_target = two.blockchain_source and one.timeframe = two.timeframe
    WHERE
        one.blockchain_source < one.blockchain_target
)

SELECT DISTINCT ON (blockchain_source, blockchain_target, is_mainnet, timeframe)
    blockchain_source::character varying,
    blockchain_target::character varying,
    is_mainnet::bool,
    timeframe::integer,
    ibc_transfers::integer,
    ibc_transfers_diff::integer,
    ibc_transfers_pending::integer,
    ibc_transfers_failed::integer,
    ibc_cashflow::bigint,
    ibc_cashflow_diff::bigint,
    ibc_cashflow_pending::bigint,
    source_to_target_ibc_transfers::integer,
    source_to_target_ibc_cashflow::bigint,
    target_to_source_ibc_transfers::integer,
    target_to_source_ibc_cashflow::bigint
FROM
    doubled_stats
WHERE
    blockchain_source < blockchain_target

$function$;
