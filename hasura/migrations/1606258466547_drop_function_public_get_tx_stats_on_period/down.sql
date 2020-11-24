CREATE OR REPLACE FUNCTION public.get_tx_stats_on_period(period_in_hours integer)
 RETURNS SETOF fn_table_txs_rating_txsdiff_ratingdiff
 LANGUAGE sql
 STABLE
AS $function$
with previous_with_current_interval as (
    select
        zone,
        txs_cnt,
        hour
    from
        total_tx_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats as (
    select
        zone,
        sum(txs_cnt) :: int as txs
    from
    (
        select
            CASE
                WHEN zone is NULL THEN name
                ELSE zone
            END AS zone,
            CASE
                WHEN txs_cnt is NULL THEN 0
                ELSE txs_cnt
            END AS txs_cnt
        from
        (
            select
                zone,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as a
        right join zones on zones.name = a.zone
    ) as b
    group by zone
), previous_interval_stats as (
    select
        zone,
        sum(txs_cnt) :: int as txs
    from
    (
        select
            CASE
            WHEN zone is NULL THEN name
            ELSE zone
        END AS zone,
        CASE
            WHEN txs_cnt is NULL THEN 0
            ELSE txs_cnt
        END AS txs_cnt
        from
        (
            select
                zone,
                txs_cnt
            from
                previous_with_current_interval
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours =>period_in_hours)
        ) as a
        right join zones on zones.name = a.zone
    ) as b
    group by zone
), current_and_previous_stats as (
    select 
        current.zone as zone,
        current.txs as txs_current,
        previous.txs as txs_previous
    from current_interval_stats as current
    left join previous_interval_stats as previous on current.zone = previous.zone
)
select
    zone,
    txs_current as txs,
    row_number() OVER (Order By txs_current desc)::int AS rating,
    txs_current - txs_previous as txs_diff,
    (row_number() OVER (Order By txs_current) - row_number() OVER (Order By txs_previous))::int as rating_diff
from current_and_previous_stats
$function$;
