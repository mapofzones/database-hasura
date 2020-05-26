CREATE OR REPLACE FUNCTION public.get_nodes_stats_with_graph_on_period(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF fn_table_zones_graph
 LANGUAGE sql
 STABLE
AS $function$
with zones_full_graph as (
    select distinct
        zone_src as source,
        zone_dest as target
    from 
        ibc_tx_hourly_stats
    -- where
        -- hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), zones_single_graph as (
    select distinct
        source as source,
        target as target
    from (
        select
            source as source,
            target as target
        from
            zones_full_graph
        union all
        select
            target as source,
            source as target
        from
            zones_full_graph
        ) as double_graph
    where source < target
), zones_json as (
select
    json_agg(stats) as zones
from
    get_full_stats_for_each_zone(period_in_hours, step_in_hours) as stats
)
select
    (select zones from zones_json limit 1)::jsonb as zones,
    case  when json_agg(json_build_object('source', source, 'target', target)) is null then '[]' 
    else json_agg(json_build_object('source', source, 'target', target))::jsonb end as graph
from 
    zones_single_graph
limit 1
$function$;
