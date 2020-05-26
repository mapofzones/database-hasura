CREATE OR REPLACE FUNCTION public.get_ibc_tx_percent_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_zone_percent
 LANGUAGE sql
 STABLE
AS $function$
with stats as (
    select
            zone_src,
            zone_dest,
            txs_cnt
        from 
            ibc_tx_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
)
select 
    ibc.zone,
    CASE ibc.txs WHEN 0 THEN 0 ELSE 100 * ibc.txs::decimal / (ibc.txs::decimal + tx.tx::decimal) END AS percent
from 
(
select 
    zone as zone, 
    CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
from (
    select 
        zones.name as zone,
        txs_cnt as txs
    from 
        stats
    right join zones on zones.name = stats.zone_src
    union all
    select 
        zones.name as zone,
        txs_cnt as txs
    from 
        stats
    right join zones on zones.name = stats.zone_dest
) as a
group by zone
) as ibc
left join
(
select 
    zone, 
    sum(txs_cnt)::int as tx
from (
    select
        CASE WHEN zone is NULL THEN name ELSE zone END AS zone,
        CASE WHEN txs_cnt is NULL THEN 0 ELSE txs_cnt END AS txs_cnt
    from (
        select
            zone,
            txs_cnt
        from 
            total_tx_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    ) as a
    right join zones on zones.name = a.zone
) as b
group by zone
) as tx
on ibc.zone = tx.zone
$function$;
