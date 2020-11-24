CREATE OR REPLACE FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF fn_table_full_stats_for_each
 LANGUAGE sql
 STABLE
AS $function$
with total_ibc_txs as (
    select
        *
    from
        get_ibc_tx_stats_on_period(period_in_hours)
), total_txs as (
    select
        *
    from
        get_tx_stats_on_period(period_in_hours)
), ibc_tx_out as (
    select
        *
    from
        get_ibc_out_tx_stats_on_period(period_in_hours)
), ibc_tx_in as (
    select
        *
    from
        get_ibc_in_tx_stats_on_period(period_in_hours)
)
select
    zones.name as zone,
    total_txs.txs as total_txs,
    total_ibc_txs.txs as total_ibc_txs,
    ibc_percent.percent as ibc_percent,
    ibc_tx_out.txs as ibc_tx_out,
    ibc_tx_in.txs as ibc_tx_in,
    channels.channels as channels_num,
    charts.chart as chart,
    total_txs.rating as total_txs_rating,
    total_txs.txs_diff as total_txs_diff,
    total_txs.rating_diff as total_txs_rating_diff,
    total_ibc_txs.rating as total_ibc_txs_rating,
    total_ibc_txs.txs_diff as total_ibc_txs_diff,
    total_ibc_txs.rating_diff as total_ibc_txs_rating_diff,
    ibc_tx_in.rating as ibc_tx_in_rating,
    ibc_tx_in.txs_diff as ibc_tx_in_diff,
    ibc_tx_in.rating_diff as ibc_tx_in_rating_diff,
    ibc_tx_out.rating as ibc_tx_out_rating,
    ibc_tx_out.txs_diff as ibc_tx_out_diff,
    ibc_tx_out.rating_diff as ibc_tx_out_rating_diff,
    total_ibc_txs.txs / (select case when sum(txs) = 0 then 1 else sum(txs) end from total_ibc_txs limit 1)::numeric as total_ibc_txs_weight,
    total_txs.txs / (select case when sum(txs) = 0 then 1 else sum(txs) end from total_txs limit 1)::numeric as total_txs_weight,
    ibc_tx_in.txs / (select case when sum(txs) = 0 then 1 else sum(txs) end from ibc_tx_in limit 1)::numeric as ibc_tx_in_weight,
    ibc_tx_out.txs / (select case when sum(txs) = 0 then 1 else sum(txs) end from ibc_tx_out limit 1)::numeric as ibc_tx_out_weight
from
    zones
left join total_txs on zones.name = total_txs.zone
left join total_ibc_txs on zones.name = total_ibc_txs.zone
left join get_ibc_tx_percent_on_period(period_in_hours) as ibc_percent on zones.name = ibc_percent.zone
left join ibc_tx_out on zones.name = ibc_tx_out.zone
left join ibc_tx_in on zones.name = ibc_tx_in.zone
left join get_ibc_channels_stats_on_period(period_in_hours) as channels on zones.name = channels.zone
left join get_ibc_tx_activities_on_period(period_in_hours, step_in_hours) as charts on zones.name = charts.zone;
$function$;
