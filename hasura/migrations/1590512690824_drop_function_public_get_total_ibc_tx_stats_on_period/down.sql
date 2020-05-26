CREATE OR REPLACE FUNCTION public.get_total_ibc_tx_stats_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_txs
 LANGUAGE sql
 STABLE
AS $function$
select 
    CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
from (
    select
            txs_cnt as txs
        from 
            ibc_tx_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) as a
$function$;
