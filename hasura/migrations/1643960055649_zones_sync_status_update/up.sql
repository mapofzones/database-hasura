CREATE OR REPLACE FUNCTION public.get_zones_statuses()
 RETURNS SETOF temp_t_get_zones_statuses
 LANGUAGE sql
 STABLE
AS $function$

select
    chain_id as zone,
    case
        when blocks_log.zone is NULL then NULL
        -- out of sync > 3000k blocks or > 1h
        when blocks_log.zone is not NULL and (blocks_log.last_updated_at <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 1) or blocks_log.last_processed_block + 3000 < zone_height.current_height) then false
        else true
end as status
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
