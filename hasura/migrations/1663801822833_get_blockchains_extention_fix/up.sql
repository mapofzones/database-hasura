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

SELECT DISTINCT on (blockchains.network_id, zones.base_token_denom)
    blockchains.network_id,
    zones.base_token_denom as base_token,
    (100.0 * zone_parameters.inflation)::numeric as inflation,
    (100.0 * ft.on_chain_supply * zone_parameters.inflation / (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent)))::numeric as staking_apr,
    zone_parameters.unbound_period::integer as unbonding_period,
    (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent))::numeric as bonded_tokens,
    (100.0 * (zone_parameters.amount_of_bonded / POW(10, pt.symbol_point_exponent)) / ft.on_chain_supply)::numeric as bonded_tokens_percent,
    zone_parameters.active_validators_quantity::integer as validators_cnt,
    nodes.cnt::integer as nodes_cnt
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

$function$;
