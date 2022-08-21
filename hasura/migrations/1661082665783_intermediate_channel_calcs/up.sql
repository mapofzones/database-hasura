
ALTER TABLE "intermediate"."channels_hourly_stats" ADD COLUMN "ibc_transfers_in" integer NOT NULL;

ALTER TABLE "intermediate"."channels_hourly_stats" ADD COLUMN "ibc_transfers_out" integer NOT NULL;

ALTER TABLE "intermediate"."channels_hourly_stats" DROP COLUMN "ibc_transfers" CASCADE;

ALTER TABLE "intermediate"."blockchains_hourly_stats" DROP COLUMN "ibc_active_addresses_cnt" CASCADE;

DROP FUNCTION IF EXISTS public.get_channels_hourly_stats(timestamp, integer);

DROP TYPE IF EXISTS public.temp_t_get_channels_hourly_stats;

CREATE TYPE public.temp_t_get_channels_hourly_stats as (
    blockchain character varying,
    channel_id character varying,
    timestamp timestamp,
    ibc_transfers_in integer,
    ibc_transfers_out integer,
    ibc_transfers_failed integer,
    ibc_cashflow_in bigint,
    ibc_cashflow_out bigint
);

CREATE OR REPLACE FUNCTION public.get_channels_hourly_stats(request_timestamp timestamp, period_in_hours integer)
 RETURNS SETOF temp_t_get_channels_hourly_stats
 LANGUAGE sql
 STABLE
AS $function$

with series as (
    select generate_series(
        date_trunc('hour', (request_timestamp)::timestamp) - ((period_in_hours-1)::text||' hour')::interval,
        date_trunc('hour', (request_timestamp)::timestamp),
        '1 hour'::interval
    ) as hour
)
, channels_series as (
    select
        zone as network_id,
        channel_id,
        hour
    from
        ibc_channels
    cross join series
)
, last_known_price as (
    SELECT DISTINCT on (zone, base_denom)
        zone,
        base_denom,
        coingecko_symbol_price_in_usd as coingecko,
        osmosis_symbol_price_in_usd as osmosis
    FROM
        public.token_prices
    WHERE
        coingecko_symbol_price_in_usd is NOT NULL
        or osmosis_symbol_price_in_usd is NOT NULL
    ORDER BY
        zone,
        base_denom,
        datetime DESC
)
, cashflow_stats as (
    select
        series.network_id,
        stats.zone_src as source,
        stats.zone_dest as target,
        series.channel_id as channel,
        series.hour as timestamp,
        coalesce(sum(
            (stats.amount / POWER(10, tokens.symbol_point_exponent))::bigint *
                coalesce(prices.coingecko_symbol_price_in_usd, prices.osmosis_symbol_price_in_usd, last_known_price.coingecko, last_known_price.osmosis, 0)
        ), 0)::bigint as usd_cashflow
    from
        channels_series as series
    left join ibc_transfer_hourly_cashflow as stats
        on stats.zone = series.network_id and stats.ibc_channel = series.channel_id and stats.hour = series.hour
    inner join derivatives
        on stats.zone = derivatives.zone and stats.derivative_denom = derivatives.full_denom
    inner join tokens
        on derivatives.base_denom = tokens.base_denom and derivatives.origin_zone = tokens.zone
    left join token_prices as prices
        on prices.zone = tokens.zone and prices.base_denom = tokens.base_denom and prices.datetime = stats.hour
    left join zones as src on src.chain_id = stats.zone_src
    left join zones as dest on dest.chain_id = stats.zone_dest
    left join last_known_price on last_known_price.zone = tokens.zone and last_known_price.base_denom = tokens.base_denom
    where
        tokens.is_price_ignored = false
    group by
        series.network_id,
        stats.zone_src,
        stats.zone_dest,
        series.channel_id,
        series.hour
)
, cashflow_stats_in as (
    select
        target as network_id,
        channel,
        timestamp,
        sum(usd_cashflow) as ibc_cashflow_in
    from
        cashflow_stats as stats
    where
        stats.network_id = stats.target
    group by
        target,
        channel,
        timestamp
)
, cashflow_stats_out as (
    select
        source as network_id,
        channel,
        timestamp,
        sum(usd_cashflow) as ibc_cashflow_out
    from
        cashflow_stats as stats
    where
        stats.network_id = stats.source
    group by
        source,
        channel,
        timestamp
)
, xfers_in_stats as (
    select
        series.network_id,
        series.channel_id,
        series.hour as timestamp,
        sum(xfers_in.txs_cnt) as ibc_transfers_in,
        sum(xfers_in.txs_fail_cnt) as ibc_transfers_in_failed
    from
        channels_series as series
    left join ibc_transfer_hourly_stats as xfers_in
        on xfers_in.zone = series.network_id and xfers_in.hour = series.hour and xfers_in.ibc_channel = series.channel_id
    where
        xfers_in.zone = xfers_in.zone_dest
    group by
        series.network_id,
        series.channel_id,
        series.hour
)
, xfers_out_stats as (
    select
        series.network_id,
        series.channel_id,
        series.hour as timestamp,
        sum(xfers_out.txs_cnt) as ibc_transfers_out,
        sum(xfers_out.txs_fail_cnt) as ibc_transfers_out_failed
    from
        channels_series as series
    left join ibc_transfer_hourly_stats as xfers_out
        on xfers_out.zone = series.network_id and xfers_out.hour = series.hour and xfers_out.ibc_channel = series.channel_id
    where
        xfers_out.zone = xfers_out.zone_src
    group by
        series.network_id,
        series.channel_id,
        series.hour
)

select
    series.network_id::character varying as blockchain,
    series.channel_id::character varying,
    series.hour::timestamp as timestamp,
    coalesce(ibc_transfers_in, 0)::integer as ibc_transfers_in,
    coalesce(ibc_transfers_out, 0)::integer as ibc_transfers_out,
    coalesce(ibc_transfers_in_failed + ibc_transfers_out_failed, 0)::integer as ibc_transfers_failed,
    coalesce(ibc_cashflow_in, 0)::bigint as ibc_cashflow_in,
    coalesce(ibc_cashflow_out, 0)::bigint as ibc_cashflow_out
from
    channels_series as series
left join xfers_in_stats as xfers_in
    on xfers_in.network_id = series.network_id and xfers_in.timestamp = series.hour and xfers_in.channel_id = series.channel_id
left join xfers_out_stats as xfers_out
    on xfers_out.network_id = series.network_id and xfers_out.timestamp = series.hour and xfers_out.channel_id = series.channel_id
left join cashflow_stats_in as cashflow_in
    on cashflow_in.network_id = series.network_id and cashflow_in.channel = series.channel_id and cashflow_in.timestamp = series.hour
left join cashflow_stats_out as cashflow_out
    on cashflow_out.network_id = series.network_id and cashflow_out.channel = series.channel_id and cashflow_out.timestamp = series.hour

$function$;
