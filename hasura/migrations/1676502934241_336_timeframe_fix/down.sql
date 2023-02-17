CREATE OR REPLACE FUNCTION public.get_blockchain_switched_stats()
 RETURNS SETOF temp_t_get_blockchain_switched_stats
 LANGUAGE sql
 STABLE
AS $function$

with
mainnet_channels as (
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
    FROM flat.channels_stats as cs
    LEFT JOIN flat.blockchains as bc ON cs.blockchain = bc.network_id
    LEFT JOIN flat.blockchains as cbc ON cs.counterparty_blockchain = cbc.network_id
    WHERE
        bc.is_mainnet = true
        and cbc.is_mainnet = true
)
, stats as (
    SELECT
        blockchain,
        timeframe,

        count(distinct channel_id) as channels_cnt,
        count(distinct counterparty_blockchain) as ibc_peers,

        sum(ibc_transfers) as ibc_transfers,
        sum(ibc_transfers_diff) as ibc_transfers_diff,
        sum(ibc_transfers_pending) as ibc_transfers_pending,
        sum(ibc_transfers_failed) as ibc_transfers_failed,-- ??????????????????
        sum(ibc_transfers_failed_diff) as ibc_transfers_failed_diff,-- ???????????????????

        sum(ibc_cashflow_in) as ibc_cashflow_in,
        sum(ibc_cashflow_in_diff) as ibc_cashflow_in_diff,
        sum(ibc_cashflow_in_pending) as ibc_cashflow_in_pending,
        sum(ibc_cashflow_out) as ibc_cashflow_out,
        sum(ibc_cashflow_out_diff) as ibc_cashflow_out_diff,
        sum(ibc_cashflow_out_pending) as ibc_cashflow_out_pending,
        sum(ibc_cashflow) as ibc_cashflow,
        sum(ibc_cashflow_diff) as ibc_cashflow_diff,
        sum(ibc_cashflow_pending) as ibc_cashflow_pending,

        (sum(ibc_cashflow_in)::numeric / coalesce(nullif(sum(ibc_cashflow_in) + sum(ibc_cashflow_out), 0), 1)::numeric) * 100.0 as ibc_cashflow_in_percent,
        (sum(ibc_cashflow_out)::numeric / coalesce(nullif(sum(ibc_cashflow_in) + sum(ibc_cashflow_out), 0), 1)::numeric) * 100.0 as ibc_cashflow_out_percent,

        (sum(ibc_transfers)::numeric / coalesce(nullif(sum(ibc_transfers) + sum(ibc_transfers_failed), 0), 1)::numeric) * 100.0 as ibc_transfers_success_rate
    FROM mainnet_channels
    GROUP BY
        blockchain,
        timeframe
)
, chains as (
    SELECT
        name,
        chain_id,
        is_mainnet,
        is_active_addresses_hidden,
        timeframe_in_hours as timeframe
    FROM
        public.zones
    CROSS JOIN flat.timeframes
    WHERE
        is_mainnet = true
)
, pure_values as (
SELECT
    chain_id as blockchain,
    chains.timeframe,

    coalesce(channels_cnt, 0) as channels_cnt,
    coalesce(ibc_peers, 0) as ibc_peers,

    coalesce(ibc_transfers, 0) as ibc_transfers,
    coalesce(ibc_transfers_diff, 0) as ibc_transfers_diff,
    coalesce(ibc_transfers_pending, 0) as ibc_transfers_pending,
    coalesce(ibc_transfers_failed, 0) as ibc_transfers_failed,-- ??????????????????
    coalesce(ibc_transfers_failed_diff, 0) as ibc_transfers_failed_diff,-- ???????????????????

    coalesce(ibc_cashflow_in, 0) as ibc_cashflow_in,
    coalesce(ibc_cashflow_in_diff, 0) as ibc_cashflow_in_diff,
    coalesce(ibc_cashflow_in_pending, 0) as ibc_cashflow_in_pending,
    coalesce(ibc_cashflow_out, 0) as ibc_cashflow_out,
    coalesce(ibc_cashflow_out_diff, 0) as ibc_cashflow_out_diff,
    coalesce(ibc_cashflow_out_pending, 0) as ibc_cashflow_out_pending,
    coalesce(ibc_cashflow, 0) as ibc_cashflow,
    coalesce(ibc_cashflow_diff, 0) as ibc_cashflow_diff,
    coalesce(ibc_cashflow_pending, 0) as ibc_cashflow_pending,

    coalesce(ibc_cashflow_in_percent, 0) as ibc_cashflow_in_percent,
    coalesce(ibc_cashflow_out_percent, 0) as ibc_cashflow_out_percent,

    coalesce(ibc_transfers_success_rate, 0) as ibc_transfers_success_rate
FROM
    chains
LEFT JOIN stats ON chains.chain_id = stats.blockchain and chains.timeframe = stats.timeframe
)
, pure_values_daily as (
    SELECT
        *
    FROM
        pure_values
    WHERE
        timeframe = 24
)
, pure_values_weekly as (
    SELECT
        *
    FROM
        pure_values
    WHERE
        timeframe = 168
)
, pure_values_monthly as (
    SELECT
        *
    FROM
        pure_values
    WHERE
        timeframe = 720
)
, daily_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By ibc_cashflow desc NULLS LAST)::int AS ibc_cashflow_rating,
        (row_number() OVER (Order By ibc_cashflow - ibc_cashflow_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow desc NULLS LAST))::int as ibc_cashflow_rating_diff,
        row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST)::int AS ibc_cashflow_in_rating,
        (row_number() OVER (Order By ibc_cashflow_in - ibc_cashflow_in_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST))::int as ibc_cashflow_in_rating_diff,
        row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST)::int AS ibc_cashflow_out_rating,
        (row_number() OVER (Order By ibc_cashflow_out - ibc_cashflow_out_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST))::int as ibc_cashflow_out_rating_diff,
        row_number() OVER (Order By ibc_transfers desc NULLS LAST)::int AS ibc_transfers_rating,
        (row_number() OVER (Order By ibc_transfers - ibc_transfers_diff desc NULLS LAST) - row_number() OVER (Order By ibc_transfers desc NULLS LAST))::int as ibc_transfers_rating_diff
    from
        pure_values_daily
)
, weekly_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By ibc_cashflow desc NULLS LAST)::int AS ibc_cashflow_rating,
        (row_number() OVER (Order By ibc_cashflow - ibc_cashflow_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow desc NULLS LAST))::int as ibc_cashflow_rating_diff,
        row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST)::int AS ibc_cashflow_in_rating,
        (row_number() OVER (Order By ibc_cashflow_in - ibc_cashflow_in_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST))::int as ibc_cashflow_in_rating_diff,
        row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST)::int AS ibc_cashflow_out_rating,
        (row_number() OVER (Order By ibc_cashflow_out - ibc_cashflow_out_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST))::int as ibc_cashflow_out_rating_diff,
        row_number() OVER (Order By ibc_transfers desc NULLS LAST)::int AS ibc_transfers_rating,
        (row_number() OVER (Order By ibc_transfers - ibc_transfers_diff desc NULLS LAST) - row_number() OVER (Order By ibc_transfers desc NULLS LAST))::int as ibc_transfers_rating_diff
    from
        pure_values_weekly
)
, monthly_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By ibc_cashflow desc NULLS LAST)::int AS ibc_cashflow_rating,
        (row_number() OVER (Order By ibc_cashflow - ibc_cashflow_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow desc NULLS LAST))::int as ibc_cashflow_rating_diff,
        row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST)::int AS ibc_cashflow_in_rating,
        (row_number() OVER (Order By ibc_cashflow_in - ibc_cashflow_in_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_in desc NULLS LAST))::int as ibc_cashflow_in_rating_diff,
        row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST)::int AS ibc_cashflow_out_rating,
        (row_number() OVER (Order By ibc_cashflow_out - ibc_cashflow_out_diff desc NULLS LAST) - row_number() OVER (Order By ibc_cashflow_out desc NULLS LAST))::int as ibc_cashflow_out_rating_diff,
        row_number() OVER (Order By ibc_transfers desc NULLS LAST)::int AS ibc_transfers_rating,
        (row_number() OVER (Order By ibc_transfers - ibc_transfers_diff desc NULLS LAST) - row_number() OVER (Order By ibc_transfers desc NULLS LAST))::int as ibc_transfers_rating_diff
    from
        pure_values_monthly
)
,mainnet_stats as (
    SELECT
        blockchain,
        timeframe,
        txs,
        txs_diff,
        ibc_active_addresses_cnt,
        ibc_active_addresses_cnt_diff,
        active_addresses_cnt,
        active_addresses_cnt_diff,
        ibc_active_addresses_percent
    FROM
        flat.blockchain_stats
    LEFT JOIN flat.blockchains on blockchain_stats.blockchain = blockchains.network_id
    WHERE
        blockchains.is_mainnet = true
)
, daily_stats as (
    SELECT
        *
    FROM
        mainnet_stats
    WHERE
        timeframe = 24
)
, weekly_stats as (
    SELECT
        *
    FROM
        mainnet_stats
    WHERE
        timeframe = 168
)
, monthly_stats as (
    SELECT
        *
    FROM
        mainnet_stats
    WHERE
        timeframe = 720
)
, daily_tx_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By txs desc NULLS LAST)::int AS txs_rating,
        (row_number() OVER (Order By txs - txs_diff desc NULLS LAST) - row_number() OVER (Order By txs desc NULLS LAST))::int as txs_rating_diff,
        row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST)::int AS ibc_active_addresses_cnt_rating,
        (row_number() OVER (Order By ibc_active_addresses_cnt - ibc_active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST))::int as ibc_active_addresses_cnt_rating_diff,
        row_number() OVER (Order By active_addresses_cnt desc NULLS LAST)::int AS active_addresses_cnt_rating,
        (row_number() OVER (Order By active_addresses_cnt - active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By active_addresses_cnt desc NULLS LAST))::int as active_addresses_cnt_rating_diff
    from
        daily_stats
), weekly_tx_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By txs desc NULLS LAST)::int AS txs_rating,
        (row_number() OVER (Order By txs - txs_diff desc NULLS LAST) - row_number() OVER (Order By txs desc NULLS LAST))::int as txs_rating_diff,
        row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST)::int AS ibc_active_addresses_cnt_rating,
        (row_number() OVER (Order By ibc_active_addresses_cnt - ibc_active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST))::int as ibc_active_addresses_cnt_rating_diff,
        row_number() OVER (Order By active_addresses_cnt desc NULLS LAST)::int AS active_addresses_cnt_rating,
        (row_number() OVER (Order By active_addresses_cnt - active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By active_addresses_cnt desc NULLS LAST))::int as active_addresses_cnt_rating_diff
    from
        weekly_stats
), monthly_tx_ratings as (
    select
        blockchain,
        timeframe,
        row_number() OVER (Order By txs desc NULLS LAST)::int AS txs_rating,
        (row_number() OVER (Order By txs - txs_diff desc NULLS LAST) - row_number() OVER (Order By txs desc NULLS LAST))::int as txs_rating_diff,
        row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST)::int AS ibc_active_addresses_cnt_rating,
        (row_number() OVER (Order By ibc_active_addresses_cnt - ibc_active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By ibc_active_addresses_cnt desc NULLS LAST))::int as ibc_active_addresses_cnt_rating_diff,
        row_number() OVER (Order By active_addresses_cnt desc NULLS LAST)::int AS active_addresses_cnt_rating,
        (row_number() OVER (Order By active_addresses_cnt - active_addresses_cnt_diff desc NULLS LAST) - row_number() OVER (Order By active_addresses_cnt desc NULLS LAST))::int as active_addresses_cnt_rating_diff
    from
        monthly_stats
)

SELECT
    pure_values.blockchain,
    true as is_mainnet,
    pure_values.timeframe,
    channels_cnt::integer,
    ibc_peers::integer,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.txs_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.txs_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.txs_rating::integer
    END as txs_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.txs_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.txs_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.txs_rating_diff::integer
    END as txs_rating_diff,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.ibc_active_addresses_cnt_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.ibc_active_addresses_cnt_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.ibc_active_addresses_cnt_rating::integer
    END as ibc_active_addresses_cnt_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.ibc_active_addresses_cnt_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.ibc_active_addresses_cnt_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.ibc_active_addresses_cnt_rating_diff::integer
    END as ibc_active_addresses_cnt_rating_diff,

    ibc_cashflow::bigint,
    ibc_cashflow_diff::bigint,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_rating::integer
    END as ibc_cashflow_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_rating_diff::integer
    END as ibc_cashflow_rating_diff,

    ibc_cashflow_pending::bigint,
    ibc_cashflow_in::bigint,
    ibc_cashflow_in_diff::bigint,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_in_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_in_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_in_rating::integer
    END as ibc_cashflow_in_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_in_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_in_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_in_rating_diff::integer
    END as ibc_cashflow_in_rating_diff,

    ibc_cashflow_in_percent::numeric,
    ibc_cashflow_in_pending::bigint,
    ibc_cashflow_out::bigint,
    ibc_cashflow_out_diff::bigint,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_out_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_out_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_out_rating::integer
    END as ibc_cashflow_out_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_cashflow_out_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_cashflow_out_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_cashflow_out_rating_diff::integer
    END as ibc_cashflow_out_rating_diff,

    ibc_cashflow_out_percent::numeric,
    ibc_cashflow_out_pending::bigint,
    ibc_transfers::integer,
    ibc_transfers_diff::integer,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_transfers_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_transfers_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_transfers_rating::integer
    END as ibc_transfers_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_ratings.ibc_transfers_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_ratings.ibc_transfers_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_ratings.ibc_transfers_rating_diff::integer
    END as ibc_transfers_rating_diff,

    ibc_transfers_pending::integer,
    ibc_transfers_success_rate::numeric,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.active_addresses_cnt_rating::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.active_addresses_cnt_rating::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.active_addresses_cnt_rating::integer
    END as active_addresses_cnt_rating,

    CASE
      WHEN pure_values.timeframe = 24 THEN daily_tx_ratings.active_addresses_cnt_rating_diff::integer
      WHEN pure_values.timeframe = 168 THEN weekly_tx_ratings.active_addresses_cnt_rating_diff::integer
      WHEN pure_values.timeframe = 720 THEN monthly_tx_ratings.active_addresses_cnt_rating_diff::integer
    END as active_addresses_cnt_rating_diff
FROM
    pure_values
LEFT JOIN daily_ratings on pure_values.timeframe = daily_ratings.timeframe and pure_values.blockchain = daily_ratings.blockchain
LEFT JOIN weekly_ratings on pure_values.timeframe = weekly_ratings.timeframe and pure_values.blockchain = weekly_ratings.blockchain
LEFT JOIN monthly_ratings on pure_values.timeframe = monthly_ratings.timeframe and pure_values.blockchain = monthly_ratings.blockchain
LEFT JOIN daily_tx_ratings on pure_values.timeframe = daily_tx_ratings.timeframe and pure_values.blockchain = daily_tx_ratings.blockchain
LEFT JOIN weekly_tx_ratings on pure_values.timeframe = weekly_tx_ratings.timeframe and pure_values.blockchain = weekly_tx_ratings.blockchain
LEFT JOIN monthly_tx_ratings on pure_values.timeframe = monthly_tx_ratings.timeframe and pure_values.blockchain = monthly_tx_ratings.blockchain

$function$;
