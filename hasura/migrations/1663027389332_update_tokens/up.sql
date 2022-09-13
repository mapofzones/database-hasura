CREATE OR REPLACE PROCEDURE public.update_tokens()
 LANGUAGE sql
AS $$

-- TRUNCATE TABLE flat.tokens;

INSERT INTO flat.tokens
SELECT
    blockchain,
    denom,
    symbol,
    logo_url,
    price,
    price_day_diff_percent,
    price_week_diff_percent,
    market_cap,
    on_chain_supply,
    token_day_trading_volume,
    token_day_trading_volume_diff_percent,
    price_month_diff_percent
FROM 
    get_tokens();

$$;
