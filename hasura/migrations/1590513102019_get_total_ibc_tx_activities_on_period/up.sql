CREATE OR REPLACE FUNCTION public.get_total_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF fn_table_txs
 LANGUAGE sql
 STABLE
AS $function$
with hours as (
  select generate_series(
    date_trunc('hour', now()) - ((period_in_hours-1)::text||' hour')::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
)
select 
    (sum(txs_cnt)*2)::int AS txs
from (
    SELECT distinct hour, txs_cnt, row_number() OVER (order by hour) AS n
    FROM (
        select 
            hours.hour as hour,
            CASE WHEN sum(ibc_transfer_hourly_stats.txs_cnt) is NULL THEN 0 ELSE sum(ibc_transfer_hourly_stats.txs_cnt) END AS txs_cnt 
        from hours
        left join ibc_transfer_hourly_stats on date_trunc('hour', ibc_transfer_hourly_stats.hour) = hours.hour
        group by 1   
    ) as a
) as b
GROUP BY n/step_in_hours
ORDER BY n/step_in_hours;
$function$;
