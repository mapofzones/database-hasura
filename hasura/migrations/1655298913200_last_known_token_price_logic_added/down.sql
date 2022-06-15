CREATE OR REPLACE FUNCTION public.get_channels_cashflow_stats(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_get_channels_cashflow_stats
 LANGUAGE sql
 STABLE
AS $function$

with channel_info as (
    select
        zone,
        counterparty_zone,
        channel,
        counterparty_channel,
        client_id,
        connection_id,
        is_opened,
        is_channel_calculable,
        is_counterparty_channel_calculable
    from
        get_channels_info()
),current_with_previous_cashflow_stats as (
    select
        stats.zone,
        stats.zone_src as source,
        stats.zone_dest as target,
        stats.hour as datetime,
        stats.ibc_channel as channel,
        channel_info.counterparty_zone,
        channel_info.counterparty_channel,
        channel_info.is_channel_calculable,
        channel_info.is_counterparty_channel_calculable,
        coalesce(sum((stats.amount / POWER(10, tokens.symbol_point_exponent))::bigint * coalesce(prices.coingecko_symbol_price_in_usd, prices.osmosis_symbol_price_in_usd, 0)), 0)::bigint as usd_cashflow
    from
        ibc_transfer_hourly_cashflow as stats
    inner join derivatives
        on stats.zone = derivatives.zone and stats.derivative_denom = derivatives.full_denom
    inner join tokens
        on derivatives.base_denom = tokens.base_denom and derivatives.origin_zone = tokens.zone
    inner join token_prices as prices
        on prices.zone = tokens.zone and prices.base_denom = tokens.base_denom and prices.datetime = stats.hour
    left join zones as src on src.chain_id = stats.zone_src
    left join zones as dest on dest.chain_id = stats.zone_dest
    left join channel_info on
        stats.zone = channel_info.zone
        and stats.ibc_channel = channel_info.channel
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours) and
        tokens.is_price_ignored = false and
        (src.is_mainnet = true or src.is_mainnet = is_mainnet_only) and
        (dest.is_mainnet = true or dest.is_mainnet = is_mainnet_only)
    group by
        stats.zone,
        stats.zone_src,
        stats.zone_dest,
        stats.hour,
        stats.ibc_channel,
        channel_info.counterparty_zone,
        channel_info.counterparty_channel,
        channel_info.is_channel_calculable,
        channel_info.is_counterparty_channel_calculable
)
, previous_cashflow_stats_in as (
    select
        target as zone,
        source,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        sum(usd_cashflow) as usd_cashflow
    from
        current_with_previous_cashflow_stats as stats
    where -- Check to prevent double summation if both zones are monitored, only received
        datetime <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and is_channel_calculable = true
        and stats.zone = stats.target
    group by
        target,
        source,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)
, current_hourly_cashflow_stats_in as (
    select
        target as zone,
        source,
        datetime,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        sum(usd_cashflow) as usd_cashflow
    from
        current_with_previous_cashflow_stats as stats
    where -- Check to prevent double summation if both zones are monitored, only received
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and is_channel_calculable = true
        and stats.zone = stats.target
    group by
        target,
        source,
        datetime,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)
, current_cashflow_stats_in as (
    select
        zone,
        source,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        sum(usd_cashflow) as usd_cashflow
    from
        current_hourly_cashflow_stats_in
    group by
        zone,
        source,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)
, previous_cashflow_stats_out as (
    select
        source as zone,
        target,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        sum(usd_cashflow) as usd_cashflow
    from
        current_with_previous_cashflow_stats as stats
    where -- Check to prevent double summation if both zones are monitored, only outputs
        datetime <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and is_channel_calculable = true
        and stats.zone = stats.source
    group by
        source,
        target,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)
, current_cashflow_stats_out as (
    select
        source as zone,
        target,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        sum(usd_cashflow) as usd_cashflow
    from
        current_with_previous_cashflow_stats as stats
    where -- Check to prevent double summation if both zones are monitored, only outputs
        datetime > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        and is_channel_calculable = true
        and stats.zone = stats.source
    group by
        source,
        target,
        channel,
        counterparty_zone,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)
, current_cashflow_out_pending_stats as (
    select
        txout.zone as zone,
        txout.target as zone_counterparty,
        txout.channel,
        txout.counterparty_channel,
        txout.is_channel_calculable,
        txout.is_counterparty_channel_calculable,
        case
            when (coalesce(txout.usd_cashflow, 0) - coalesce(txin.usd_cashflow, 0)) > 0 then coalesce(txout.usd_cashflow, 0) - coalesce(txin.usd_cashflow, 0) else 0
        end as pending
    from
        current_cashflow_stats_out as txout
    left join current_cashflow_stats_in as txin
        on txout.zone = txin.source
            and txout.target = txin.zone
            and txout.channel = txin.counterparty_channel
            and txout.counterparty_channel = txin.channel
)
, cashflow_chart as (
    select
        zone,
        counterparty_zone,
        channel,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable,
        json_agg(json_build_object(chart_key, cashflow)) as chart
    from (
                select
                    zone,
                    counterparty_zone,
                    channel,
                    counterparty_channel,
                    is_channel_calculable,
                    is_counterparty_channel_calculable,
                    n/step_in_hours as chart_key,
                    sum(cashflow)::bigint as cashflow
                from (
                    SELECT distinct
                        zone,
                        counterparty_zone,
                        channel,
                        counterparty_channel,
                        is_channel_calculable,
                        is_counterparty_channel_calculable,
                        hour,
                        cashflow,
                        row_number() OVER (PARTITION BY zone, channel order by hour) - 1 AS n
                    FROM (
                        select
                            series.zone,
                            series.counterparty_zone,
                            series.channel,
                            series.counterparty_channel,
                            series.is_channel_calculable,
                            series.is_counterparty_channel_calculable,
                            series.hour,
                            coalesce(sum(ibc_in_data.usd_cashflow), 0) + coalesce(sum(ibc_out_data.usd_cashflow), 0) AS cashflow
                        from get_channels_series(period_in_hours) as series
                        left join current_hourly_cashflow_stats_in as ibc_in_data
                            on date_trunc('hour', ibc_in_data.datetime) = series.hour
                                and series.zone = ibc_in_data.zone
                                and series.channel = ibc_in_data.channel
                        left join current_hourly_cashflow_stats_in as ibc_out_data
                            on date_trunc('hour', ibc_out_data.datetime) = series.hour
                                and series.zone = ibc_out_data.source
                                and series.channel = ibc_out_data.counterparty_channel
                                and series.counterparty_zone = ibc_out_data.zone
                                and series.counterparty_channel = ibc_out_data.channel
                        group by
                            series.zone,
                            series.counterparty_zone,
                            series.channel,
                            series.counterparty_channel,
                            series.is_channel_calculable,
                            series.is_counterparty_channel_calculable,
                            series.hour
                    ) as a
                ) as b
                GROUP BY
                    zone,
                    counterparty_zone,
                    channel,
                    counterparty_channel,
                    is_channel_calculable,
                    is_counterparty_channel_calculable,
                    n/step_in_hours
        ) as ibc_chart
    group by
        zone,
        counterparty_zone,
        channel,
        counterparty_channel,
        is_channel_calculable,
        is_counterparty_channel_calculable
)

select
    channels.zone,
    channels.counterparty_zone,
    channels.channel,
    channels.counterparty_channel,
    channels.is_channel_calculable,
    channels.is_counterparty_channel_calculable,
    channels.client_id,
    channels.connection_id,
    channels.is_opened,
    coalesce(tx_in.usd_cashflow, 0)::bigint as cashflow_in,
    (coalesce(tx_in.usd_cashflow, 0) - coalesce(previous_tx_in.usd_cashflow, 0))::bigint as cashflow_in_diff,
    coalesce(counterparty_tx_out_pending.pending, 0)::bigint as cashflow_in_pending,
    coalesce(counterparty_tx_in.usd_cashflow, 0)::bigint as cashflow_out,
    (coalesce(counterparty_tx_in.usd_cashflow, 0) - coalesce(previous_counterparty_tx_in.usd_cashflow, 0))::bigint as cashflow_out_diff,
    coalesce(tx_out_pending.pending, 0)::bigint as cashflow_out_pending,
    chart.chart::jsonb as chart
from
    channel_info as channels
left join current_cashflow_stats_in as tx_in
    on channels.zone = tx_in.zone and channels.channel = tx_in.channel
left join current_cashflow_stats_in as counterparty_tx_in
    on channels.counterparty_zone = counterparty_tx_in.zone and channels.counterparty_channel = counterparty_tx_in.channel
        and channels.zone = counterparty_tx_in.source and channels.channel = counterparty_tx_in.counterparty_channel
left join current_cashflow_stats_out as tx_out
    on channels.zone = tx_out.zone and channels.channel = tx_out.channel
left join current_cashflow_out_pending_stats as tx_out_pending
    on channels.zone = tx_out_pending.zone and channels.channel = tx_out_pending.channel
left join current_cashflow_out_pending_stats as counterparty_tx_out_pending
    on channels.counterparty_zone = counterparty_tx_out_pending.zone and channels.counterparty_channel = counterparty_tx_out_pending.channel
        and channels.zone = counterparty_tx_out_pending.zone_counterparty and channels.channel = counterparty_tx_out_pending.counterparty_channel
left join previous_cashflow_stats_in as previous_tx_in
    on channels.zone = previous_tx_in.zone and channels.channel = previous_tx_in.channel
left join previous_cashflow_stats_out as previous_tx_out
    on channels.zone = previous_tx_out.zone and channels.channel = previous_tx_out.channel
left join previous_cashflow_stats_in as previous_counterparty_tx_in
    on channels.counterparty_zone = previous_counterparty_tx_in.zone and channels.counterparty_channel = previous_counterparty_tx_in.channel
        and channels.zone = previous_counterparty_tx_in.source and channels.channel = previous_counterparty_tx_in.counterparty_channel
left join current_cashflow_stats_out as counterparty_tx_out
    on channels.counterparty_zone = counterparty_tx_out.zone and channels.counterparty_channel = counterparty_tx_out.channel
        and channels.zone = counterparty_tx_out.target and channels.channel = counterparty_tx_out.counterparty_channel
left join cashflow_chart as chart
    on channels.zone = chart.zone and channels.channel = chart.channel

$function$;
