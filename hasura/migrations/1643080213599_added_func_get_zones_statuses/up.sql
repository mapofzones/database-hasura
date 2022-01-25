DROP FUNCTION IF EXISTS public.get_zones_statuses();

DROP TYPE IF EXISTS public.temp_t_get_zones_statuses;

CREATE TYPE public.temp_t_get_zones_statuses as (
    zone character varying,
    status bool
);

CREATE OR REPLACE FUNCTION public.get_zones_statuses()
 RETURNS SETOF temp_t_get_zones_statuses
 LANGUAGE sql
 STABLE
AS $function$

select
    chain_id as zone,
    case
        when blocks_log.zone is NULL then NULL
        --change false statement when out of sync
        when blocks_log.zone is not NULL and blocks_log.last_updated_at <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 1) then false
        else true
    end as status
from
    zones
left join blocks_log
    on zones.chain_id = blocks_log.zone

$function$;
