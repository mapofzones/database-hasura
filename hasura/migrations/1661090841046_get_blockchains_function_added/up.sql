DROP FUNCTION IF EXISTS public.get_blockchains();

DROP TYPE IF EXISTS public.temp_t_get_blockchains;

CREATE TYPE public.temp_t_get_blockchains as (
    network_id character varying,
    name character varying,
    logo_url character varying,
    is_synced bool,
    website character varying,
    is_mainnet bool
);

CREATE OR REPLACE FUNCTION public.get_blockchains()
 RETURNS SETOF temp_t_get_blockchains
 LANGUAGE sql
 STABLE
AS $function$

select
    chain_id as network_id,
    name,
    zone_label_url as logo_url,
    case
        when blocks_log.zone is NULL then NULL
        -- out of sync > 3000k blocks or > 1h
        when blocks_log.zone is not NULL and (blocks_log.last_updated_at <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 1) or blocks_log.last_processed_block + 3000 < zone_height.current_height) then false
        else true
    end as is_synced,
    website,
    is_mainnet
from
    zones
        left join blocks_log
                  on zones.chain_id = blocks_log.zone
        left join (
        SELECT
            zone,
            MAX(last_block_height) as current_height
        FROM zone_nodes
        WHERE is_alive = true
        GROUP BY zone
    ) as zone_height
                  on zones.chain_id = zone_height.zone

$function$;
