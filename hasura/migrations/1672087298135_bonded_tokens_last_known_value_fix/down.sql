CREATE OR REPLACE FUNCTION public.get_blockchains_extention()
RETURNS SETOF temp_t_get_blockchains_extention
LANGUAGE sql
STABLE
AS $function$

with subquery as (
SELECT DISTINCT
    zone,
    ip
FROM public.zone_nodes
WHERE
    is_alive = true or is_rpc_addr_active = true or is_lcd_addr_active = true
)
, nodes as (
    SELECT
        zone as blockchain,
        COUNT(*) as cnt
    FROM subquery
    GROUP BY zone
)
, actual_dataset as (
SELECT DISTINCT on (blockchains.network_id, zones.base_token_denom)
    blockchains.network_id,
    zones.base_token_denom as base_token,
    zone_parameters.inflation::numeric as inflation,
    (100.0 * ft.on_chain_supply * zone_parameters.inflation / (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent)))::numeric as staking_apr,
    zone_parameters.unbound_period::integer as unbonding_period,
    (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent))::numeric as bonded_tokens,
    (100.0 * (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent)) / ft.on_chain_supply)::numeric as bonded_tokens_percent,
    zone_parameters.active_validators_quantity::integer as validators_cnt,
    nodes.cnt::integer as nodes_cnt,
    pt.symbol_point_exponent,
    ft.on_chain_supply
FROM
    flat.blockchains
LEFT JOIN public.zones on zones.chain_id = blockchains.network_id
LEFT JOIN public.zone_parameters on zone_parameters.zone = blockchains.network_id
LEFT JOIN public.tokens as pt on pt.zone = blockchains.network_id and pt.base_denom = zones.base_token_denom
LEFT JOIN flat.tokens as ft on ft.blockchain = blockchains.network_id and ft.denom = zones.base_token_denom
LEFT JOIN nodes on nodes.blockchain = blockchains.network_id
WHERE
    zones.is_mainnet = true
ORDER BY
    blockchains.network_id,
    zones.base_token_denom,
    datetime DESC
)
, last_known_inflation as (
    SELECT DISTINCT on (zone)
        zone,
        inflation
    FROM
        public.zone_parameters
    WHERE
        inflation is NOT NULL
    ORDER BY
        zone,
        datetime DESC
)
, last_known_unbonding as (
    SELECT DISTINCT on (zone)
        zone,
        unbound_period as unbonding_period
    FROM
        public.zone_parameters
    WHERE
        unbound_period is NOT NULL
    ORDER BY
        zone,
        datetime DESC
)
, last_known_bonded as (
    SELECT DISTINCT on (zone)
        zone,
        amount_of_bonded as bonded_tokens
    FROM
        public.zone_parameters
    WHERE
        amount_of_bonded is NOT NULL
    ORDER BY
        zone,
        datetime DESC
)
, last_known_validators as (
    SELECT DISTINCT on (zone)
        zone,
        active_validators_quantity as validators_cnt
    FROM
        public.zone_parameters
    WHERE
        active_validators_quantity is NOT NULL
    ORDER BY
        zone,
        datetime DESC
)

SELECT
    network_id,
    base_token,
    (100.0 * nullif(coalesce(actual_dataset.inflation, lki.inflation, -1), -1))::numeric as inflation,
        CASE
            WHEN actual_dataset.inflation = 0 THEN 0::NUMERIC
        ELSE (100.0 * on_chain_supply * nullif(coalesce(actual_dataset.inflation, lki.inflation, -1), -1) / nullif(coalesce(actual_dataset.bonded_tokens, lkb.bonded_tokens, 0), 0))::numeric
END as staking_apr,
    nullif(coalesce(actual_dataset.unbonding_period, lku.unbonding_period, -1), -1) as unbonding_period,
    nullif(coalesce(actual_dataset.bonded_tokens, lkb.bonded_tokens, -1), -1) as bonded_tokens,
    (100.0 * nullif(coalesce(actual_dataset.bonded_tokens, lkb.bonded_tokens, -1), -1) / nullif(on_chain_supply, 0))::numeric as bonded_tokens_percent,
    nullif(coalesce(actual_dataset.validators_cnt, lkv.validators_cnt, -1), -1) as validators_cnt,
    nodes_cnt
FROM
    actual_dataset
LEFT JOIN last_known_inflation as lki ON actual_dataset.network_id = lki.zone
LEFT JOIN last_known_unbonding as lku ON actual_dataset.network_id = lku.zone
LEFT JOIN last_known_bonded as lkb ON actual_dataset.network_id = lkb.zone
LEFT JOIN last_known_validators as lkv ON actual_dataset.network_id = lkv.zone

$function$;
