DROP FUNCTION IF EXISTS public.get_ft_chanels_stats();

DROP TYPE IF EXISTS public.temp_t_ft_channels_stats;






CREATE TYPE public.temp_t_ft_channels_stats as (
    zone character varying,
    client_id character varying,
    connection_id character varying,
    channel_id character varying,
    timeframe integer,
    zone_counerparty character varying,
    is_opened boolean,
    ibc_tx integer,
    ibc_tx_diff integer,
    ibc_tx_failed integer,
    ibc_tx_failed_diff integer,
    zone_label_url character varying,
    zone_counterparty_label_url character varying,
    zone_readable_name character varying,
    zone_counterparty_readable_name character varying,
    is_zone_counerparty_mainnet boolean,
    zone_label_url2 character varying,
    zone_counterparty_label_url2 character varying,
    zone_counterparty_channel_id character varying,
    zone_website character varying,
    ibc_cashflow_in bigint,
    ibc_cashflow_in_diff bigint,
    ibc_cashflow_out bigint,
    ibc_cashflow_out_diff bigint,
    ibc_tx_success_rate bigint,
    ibc_tx_success_rate_diff bigint
);

CREATE OR REPLACE FUNCTION public.get_ft_chanels_stats(period_in_hours integer)
 RETURNS SETOF temp_t_ft_channels_stats
 LANGUAGE sql
 STABLE
AS $function$

with current_with_previous as (
    select
        zone,
        hour,
        ibc_channel,
        txs_cnt,
        txs_fail_cnt
    from
        ibc_transfer_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_stats as (
    select
        zone as zone,
        ibc_channel as channel,
        COALESCE(sum(txs_cnt), 0)::int as ibc_tx,
        COALESCE(sum(txs_fail_cnt), 0)::int as ibc_tx_failed
    from
        current_with_previous
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by zone, ibc_channel
), previous_stats as (
    select
        zone as zone,
        ibc_channel as channel,
        COALESCE(sum(txs_cnt), 0)::int as ibc_tx_previous,
        COALESCE(sum(txs_fail_cnt), 0)::int as ibc_tx_failed_previous
    from
        current_with_previous
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by zone, ibc_channel
), ibc_transfer_stats as (
    select
        channel.zone,
        channel.channel_id as channel,
        COALESCE(current.ibc_tx, 0) as ibc_tx,
        COALESCE(COALESCE(current.ibc_tx, 0) - COALESCE(previous.ibc_tx_previous, 0), 0)::int as ibc_tx_diff,
        COALESCE(current.ibc_tx_failed, 0) as ibc_tx_failed,
        COALESCE(COALESCE(current.ibc_tx_failed, 0) - COALESCE(previous.ibc_tx_failed_previous, 0), 0)::int as ibc_tx_failed_diff
    from
        ibc_channels as channel
    full outer join current_stats as current
        on current.zone = channel.zone
        and current.channel = channel.channel_id
    full outer join previous_stats as previous
        on previous.zone = channel.zone
        and previous.channel = channel.channel_id
)







-- cashflow start
,previous_with_current_hourly_cashflow as (
    select
        cashflow.zone,
        cashflow.zone_src,
        cashflow.zone_dest,
        cashflow.hour as datetime,
        cashflow.ibc_channel,
        ((cashflow.amount / POWER(10,tokens.symbol_point_exponent))::bigint * prices.coingecko_symbol_price_in_usd)::bigint as usd_cashflow
    from
        ibc_transfer_hourly_cashflow as cashflow
    inner join
        derivatives
    on
        cashflow.zone = derivatives.zone and cashflow.derivative_denom = derivatives.full_denom
    inner join
        tokens
    on
        derivatives.base_denom = tokens.base_denom and derivatives.origin_zone = tokens.zone
    inner join
        token_prices as prices
    on
        prices.zone = tokens.zone and prices.base_denom = tokens.base_denom and prices.datetime = cashflow.hour
    where
        tokens.is_price_ignored = false
        and hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
    order by
        hour
), current_cashflow as (
    select
        zone,
        zone_src,
        zone_dest,
        ibc_channel,
        COALESCE(sum(usd_cashflow), 0)::bigint as usd_cashflow
    from
        previous_with_current_hourly_cashflow
    where
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone,
        zone_src,
        zone_dest,
        ibc_channel
), previous_cashflow as (
    select
        zone,
        zone_src,
        zone_dest,
        ibc_channel,
        COALESCE(sum(usd_cashflow), 0)::bigint as usd_cashflow
    from
        previous_with_current_hourly_cashflow
    where
        datetime <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    group by
        zone,
        zone_src,
        zone_dest,
        ibc_channel
), cashflow_stats as (
    select
        COALESCE(current.zone, previous.zone) as zone,
        COALESCE(current.ibc_channel, previous.ibc_channel) as ibc_channel,
        COALESCE(case when current.zone = current.zone_dest then current.usd_cashflow else 0 end, 0)::bigint as ibc_cashflow_in,
        COALESCE(case when current.zone = current.zone_src then current.usd_cashflow else 0 end, 0)::bigint as ibc_cashflow_out,
        COALESCE(case when current.zone = current.zone_dest then current.usd_cashflow else 0 end, 0)::bigint -
            COALESCE(case when previous.zone = previous.zone_dest then previous.usd_cashflow else 0 end, 0)::bigint as ibc_cashflow_in_diff,
        COALESCE(case when current.zone = current.zone_src then current.usd_cashflow else 0 end, 0)::bigint -
            COALESCE(case when previous.zone = previous.zone_src then previous.usd_cashflow else 0 end, 0)::bigint as ibc_cashflow_out_diff
    from
        current_cashflow as current
    full outer join
        previous_cashflow as previous
    on
        current.zone = previous.zone
        and current.zone_src = previous.zone_src
        and current.zone_dest = previous.zone_dest
        and current.ibc_channel = previous.ibc_channel
)

select
    channels.zone as zone,
    connections.client_id as client_id,
    channels.connection_id as connection_id,
    channels.channel_id as channel_id,
    period_in_hours as timeframe,
    clients.chain_id as zone_counerparty,
    channels.is_opened as is_opened,
    COALESCE(transfer_stats.ibc_tx, 0) as ibc_tx,
    COALESCE(transfer_stats.ibc_tx_diff, 0) as ibc_tx_diff,
    COALESCE(transfer_stats.ibc_tx_failed, 0) as ibc_tx_failed,
    COALESCE(transfer_stats.ibc_tx_failed_diff, 0) as ibc_tx_failed_diff,
    zones_current.zone_label_url as zone_label_url,
    zones_counerparty.zone_label_url as zone_counterparty_label_url,
    zones_current.name as zone_readable_name,
    zones_counerparty.name as zone_counterparty_readable_name,
    zones_counerparty.is_mainnet as is_zone_counerparty_mainnet,
    zones_current.zone_label_url2 as zone_label_url2,
    zones_counerparty.zone_label_url2 as zone_counterparty_label_url2,
    channels.counterparty_channel_id as zone_counterparty_channel_id,
    zones_current.website as zone_website,
    COALESCE(cashflow.ibc_cashflow_in, 0) as ibc_cashflow_in,
    COALESCE(cashflow.ibc_cashflow_in_diff, 0) as ibc_cashflow_in_diff,
    COALESCE(cashflow.ibc_cashflow_out, 0) as ibc_cashflow_out,
    COALESCE(cashflow.ibc_cashflow_out_diff, 0) as ibc_cashflow_out_diff,
    100 * ((COALESCE(transfer_stats.ibc_tx, 0) - COALESCE(transfer_stats.ibc_tx_failed, 0))::numeric / case when transfer_stats.ibc_tx = 0 or transfer_stats.ibc_tx is NULL then 1 else transfer_stats.ibc_tx end)::bigint as ibc_tx_success_rate,
    (100 * ((COALESCE(transfer_stats.ibc_tx, 0) - COALESCE(transfer_stats.ibc_tx_failed, 0))::numeric / case when transfer_stats.ibc_tx = 0 or transfer_stats.ibc_tx is NULL then 1 else transfer_stats.ibc_tx end)::bigint) -
        (100 * (((COALESCE(transfer_stats.ibc_tx, 0) - COALESCE(transfer_stats.ibc_tx_failed, 0)) - (COALESCE(transfer_stats.ibc_tx_diff, 0) - COALESCE(transfer_stats.ibc_tx_failed_diff, 0)))::numeric /
            case when (COALESCE(transfer_stats.ibc_tx, 1) - COALESCE(transfer_stats.ibc_tx_diff, 0)) = 0 then 1 else (COALESCE(transfer_stats.ibc_tx, 1) - COALESCE(transfer_stats.ibc_tx_diff, 0)) end)::bigint)
                as ibc_tx_success_rate_diff
from
    ibc_channels as channels
inner join ibc_connections as connections
    on channels.zone = connections.zone and channels.connection_id = connections.connection_id
inner join ibc_clients as clients
    on connections.zone = clients.zone and connections.client_id = clients.client_id
inner join ibc_transfer_stats as transfer_stats
    on transfer_stats.zone = channels.zone and transfer_stats.channel = channels.channel_id
inner join zones as zones_current
    on zones_current.chain_id = channels.zone
inner join zones as zones_counerparty
    on zones_counerparty.chain_id = clients.chain_id
left join cashflow_stats as cashflow
    on channels.zone = cashflow.zone and channels.channel_id = cashflow.ibc_channel
$function$;
