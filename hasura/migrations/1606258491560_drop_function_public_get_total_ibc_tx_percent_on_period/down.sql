CREATE OR REPLACE FUNCTION public.get_total_ibc_tx_percent_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_percent
 LANGUAGE sql
 STABLE
AS $function$
select 100*(
    select 
        CASE WHEN sum(txs)::decimal is NULL THEN 0 ELSE sum(txs)::decimal  END as txs
    from (
        select
                txs_cnt as txs
            from 
                ibc_transfer_hourly_stats
            where 
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
    ) as a)
/
(
    select
        CASE WHEN sum(txs_cnt) :: decimal is NULL THEN 1 ELSE sum(txs_cnt) :: decimal END  as txs
    from
        total_tx_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) 
as percent;
$function$;
