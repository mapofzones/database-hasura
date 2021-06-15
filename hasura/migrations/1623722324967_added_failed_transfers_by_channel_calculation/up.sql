CREATE OR REPLACE FUNCTION public.get_chanels_stats()
 RETURNS SETOF temp_t_channels_stats
 LANGUAGE sql
 STABLE
AS $function$

with two_month as (
    select
        zone,
        hour,
        ibc_channel,
        txs_cnt,
        txs_fail_cnt
    from
        ibc_transfer_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*720)
), month_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_30d,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_30d_failed
    from
        two_month
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 720)
    group by zone, ibc_channel
), previous_month_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_30d_previous,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_30d_failed_previous
    from
        two_month
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 720)
    group by zone, ibc_channel
), week_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_7d,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_7d_failed
    from
        two_month
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 168)
    group by zone, ibc_channel
), previous_week_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_7d_previous,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_7d_failed_previous
    from
        two_month
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 168) and
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*168)
    group by zone, ibc_channel
), day_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_1d,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_1d_failed
    from
        two_month
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 24)
    group by zone, ibc_channel
), previous_day_stats as (
    select
        zone as zone, 
        ibc_channel as channel,
        CASE WHEN sum(txs_cnt)::int is NULL THEN 0 ELSE sum(txs_cnt)::int  END as ibc_tx_1d_previous,
        CASE WHEN sum(txs_fail_cnt)::int is NULL THEN 0 ELSE sum(txs_fail_cnt)::int  END as ibc_tx_1d_failed_previous
    from
        two_month
    where
        hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 24) and
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*24)
    group by zone, ibc_channel
), ibc_transfer_stats as (
    select
        channel.zone,
        channel.channel_id as channel,
        month_stats.ibc_tx_30d,
        month_stats.ibc_tx_30d - previous_month_stats.ibc_tx_30d_previous as ibc_tx_30d_diff,
        month_stats.ibc_tx_30d_failed,
        month_stats.ibc_tx_30d_failed - previous_month_stats.ibc_tx_30d_failed_previous as ibc_tx_30d_failed_diff,
        week_stats.ibc_tx_7d,
        week_stats.ibc_tx_7d - previous_week_stats.ibc_tx_7d_previous as ibc_tx_7d_diff,
        week_stats.ibc_tx_7d_failed,
        week_stats.ibc_tx_7d_failed - previous_week_stats.ibc_tx_7d_failed_previous as ibc_tx_7d_failed_diff,
        day_stats.ibc_tx_1d,
        day_stats.ibc_tx_1d - previous_day_stats.ibc_tx_1d_previous as ibc_tx_1d_diff,
        day_stats.ibc_tx_1d_failed,
        day_stats.ibc_tx_1d_failed - previous_day_stats.ibc_tx_1d_failed_previous as ibc_tx_1d_failed_diff
    from
        ibc_channels as channel
    full outer join month_stats
        on month_stats.zone = channel.zone and month_stats.channel = channel.channel_id
    full outer join previous_month_stats
        on previous_month_stats.zone = channel.zone
        and previous_month_stats.channel = channel.channel_id
    full outer join week_stats
        on week_stats.zone = channel.zone
        and week_stats.channel = channel.channel_id
    full outer join previous_week_stats
        on previous_week_stats.zone = channel.zone
        and previous_week_stats.channel = channel.channel_id
    full outer join day_stats
        on day_stats.zone = channel.zone
        and day_stats.channel = channel.channel_id
    full outer join previous_day_stats
        on previous_day_stats.zone = channel.zone
        and previous_day_stats.channel = channel.channel_id
)
    
select
    channels.zone as zone,
    connections.client_id as client_id,
    channels.connection_id as connection_id,
    channels.channel_id as channel_id,
    clients.chain_id as zone_counerparty,
    channels.is_opened as is_opened,
    CASE WHEN transfer_stats.ibc_tx_1d is NULL THEN 0 ELSE transfer_stats.ibc_tx_1d END as ibc_tx_1d,
    CASE WHEN transfer_stats.ibc_tx_1d_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_1d_diff END as ibc_tx_1d_diff,
    CASE WHEN transfer_stats.ibc_tx_1d_failed is NULL THEN 0 ELSE transfer_stats.ibc_tx_1d_failed END as ibc_tx_1d_failed,
    CASE WHEN transfer_stats.ibc_tx_1d_failed_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_1d_failed_diff END as ibc_tx_1d_failed_diff,
    CASE WHEN transfer_stats.ibc_tx_7d is NULL THEN 0 ELSE transfer_stats.ibc_tx_7d END as ibc_tx_7d,
    CASE WHEN transfer_stats.ibc_tx_7d_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_7d_diff END as ibc_tx_7d_diff,
    CASE WHEN transfer_stats.ibc_tx_7d_failed is NULL THEN 0 ELSE transfer_stats.ibc_tx_7d_failed END as ibc_tx_7d_failed,
    CASE WHEN transfer_stats.ibc_tx_7d_failed_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_7d_failed_diff END as ibc_tx_7d_failed_diff,
    CASE WHEN transfer_stats.ibc_tx_30d is NULL THEN 0 ELSE transfer_stats.ibc_tx_30d END as ibc_tx_30d,
    CASE WHEN transfer_stats.ibc_tx_30d_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_30d_diff END as ibc_tx_30d_diff,
    CASE WHEN transfer_stats.ibc_tx_30d_failed is NULL THEN 0 ELSE transfer_stats.ibc_tx_30d_failed END as ibc_tx_30d_failed,
    CASE WHEN transfer_stats.ibc_tx_30d_failed_diff is NULL THEN 0 ELSE transfer_stats.ibc_tx_30d_failed_diff END as ibc_tx_30d_failed_diff
from
    ibc_channels as channels
inner join ibc_connections as connections
    on channels.zone = connections.zone and channels.connection_id = connections.connection_id
inner join ibc_clients as clients
    on connections.zone = clients.zone and connections.client_id = clients.client_id
inner join ibc_transfer_stats as transfer_stats
    on transfer_stats.zone = channels.zone and transfer_stats.channel = channels.channel_id

$function$;
