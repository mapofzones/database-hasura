CREATE OR REPLACE FUNCTION public.get_tokens()
 RETURNS SETOF temp_t_get_tokens
 LANGUAGE sql
 STABLE
AS $function$

with mainnet_tokens as (
    SELECT
        tokens.zone as blockchain,
        tokens.base_denom as denom,
        tokens.symbol,
        tokens.logo_url,
        symbol_point_exponent
    FROM
        public.tokens
    LEFT JOIN public.zones on tokens.zone = zones.chain_id
    WHERE
      is_mainnet = true
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
, last_known_supply as (
    SELECT DISTINCT on (zone, base_denom)
        zone,
        base_denom,
        nullif(symbol_supply, 0) as supply
    FROM
        public.token_prices
    WHERE
        symbol_supply is NOT NULL
    ORDER BY
        zone,
        base_denom,
        datetime DESC
)
, prices as (
    SELECT DISTINCT on (blockchain, denom)
        blockchain,
        denom,
        symbol,
        logo_url,
        symbol_point_exponent,
        coalesce(tp.coingecko_symbol_price_in_usd, tp.osmosis_symbol_price_in_usd, lkp.coingecko, lkp.osmosis, 0) as price,
        (nullif(coalesce(symbol_supply, supply, 0), 0) * coalesce(tp.coingecko_symbol_price_in_usd, tp.osmosis_symbol_price_in_usd, lkp.coingecko, lkp.osmosis, 0)) / nullif(POW(10, symbol_point_exponent), 0)  as market_cap,
        nullif(coalesce(symbol_supply, supply, 0), 0) / nullif(POW(10, symbol_point_exponent), 0) as on_chain_supply,
        coingecko_symbol_total_volumes_in_usd as token_day_trading_volume
    FROM
        mainnet_tokens as mt
    LEFT JOIN public.token_prices as tp on mt.blockchain = tp.zone and mt.denom = tp.base_denom
    LEFT JOIN last_known_price as lkp on mt.blockchain = lkp.zone and mt.denom = lkp.base_denom
    LEFT JOIN last_known_supply as lks on mt.blockchain = lks.zone and mt.denom = lks.base_denom
    WHERE
      (tp.coingecko_symbol_price_in_usd > 0 or tp.osmosis_symbol_price_in_usd > 0 or lkp.coingecko > 0 or lkp.osmosis > 0)
      and datetime = (SELECT MAX(datetime) FROM public.token_prices tp2 WHERE tp.zone = tp2.zone and tp.base_denom = tp2.base_denom and tp.datetime = tp2.datetime)
    ORDER BY
        blockchain,
        denom,
        datetime desc
)
, day_ago_prices as (
    SELECT
        blockchain,
        denom,
        coalesce(coingecko_symbol_price_in_usd, osmosis_symbol_price_in_usd, 0) as price,
        coingecko_symbol_total_volumes_in_usd as token_day_trading_volume
    FROM
        prices
    LEFT JOIN public.token_prices as tp on prices.blockchain = tp.zone and prices.denom = tp.base_denom
    WHERE
        datetime = date_trunc('hour', now() - make_interval(hours => 24))
)
, week_ago_prices as (
    SELECT
        blockchain,
        denom,
        coalesce(coingecko_symbol_price_in_usd, osmosis_symbol_price_in_usd, 0) as price
    FROM
        prices
    LEFT JOIN public.token_prices as tp on prices.blockchain = tp.zone and prices.denom = tp.base_denom
    WHERE
        datetime = date_trunc('hour', now() - make_interval(hours => 168))
)
, month_ago_prices as (
    SELECT
        blockchain,
        denom,
        coalesce(coingecko_symbol_price_in_usd, osmosis_symbol_price_in_usd, 0) as price
    FROM
        prices
    LEFT JOIN public.token_prices as tp on prices.blockchain = tp.zone and prices.denom = tp.base_denom
    WHERE
        datetime = date_trunc('hour', now() - make_interval(hours => 720))
)

SELECT
    prices.blockchain::character varying,
    prices.denom::character varying,
    prices.symbol::character varying,
    prices.logo_url::character varying,
    prices.price::numeric,
    (100 * (prices.price - day_ago.price) / nullif(day_ago.price, 0))::numeric as price_day_diff_percent,
    (100 * (prices.price - week_ago.price) / nullif(week_ago.price, 0))::numeric as price_week_diff_percent,
    prices.market_cap::numeric,
    prices.on_chain_supply::numeric,
    prices.token_day_trading_volume::numeric,
    (100 * (prices.token_day_trading_volume - day_ago.token_day_trading_volume) / nullif(day_ago.token_day_trading_volume, 0))::numeric as token_day_trading_volume_diff_percent,
    (100 * (prices.price - month_ago.price) / nullif(month_ago.price, 0))::numeric as price_month_diff_percent
FROM
    prices
    LEFT JOIN day_ago_prices as day_ago on prices.blockchain = day_ago.blockchain and prices.denom = day_ago.denom
    LEFT JOIN week_ago_prices as week_ago on prices.blockchain = week_ago.blockchain and prices.denom = week_ago.denom
    LEFT JOIN month_ago_prices as month_ago on prices.blockchain = month_ago.blockchain and prices.denom = month_ago.denom

$function$;
