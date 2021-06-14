CREATE OR REPLACE FUNCTION public.get_zones_graphs(period_in_hours integer)
    RETURNS SETOF temp_t_zones_graphs
    LANGUAGE sql
    STABLE
AS $function$

with base_data_template as (
    select
        clients.zone,
        clients.chain_id,
        channels.channel_id,
        channels.is_opened,
        sum(transfers.txs_cnt) as txs
    from
        ibc_channels as channels
    inner join ibc_connections as connections
        on channels.connection_id = connections.connection_id and channels.zone = connections.zone
    inner join ibc_clients as clients
        on connections.client_id = clients.client_id and connections.zone = clients.zone
    left join ibc_transfer_hourly_stats as transfers
        on transfers.ibc_channel = channels.channel_id and transfers.zone = channels.zone
    where
        (hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours) or hour is NULL)
    group by
        clients.zone,
        clients.chain_id,
        channels.channel_id,
        channels.is_opened
), calculate_stats as (
    select
        zone as zone,
        chain_id as counterparty_zone,
        count(CASE WHEN is_opened = true THEN channel_id ELSE NULL END) as channels_cnt_open,
        count(CASE WHEN txs > 0 THEN txs ELSE NULL END) as channels_cnt_active,
        100 * count(CASE WHEN txs > 0 THEN txs ELSE NULL END)::numeric /
            CASE WHEN count(CASE WHEN is_opened = true THEN channel_id ELSE NULL END) > 0 THEN
                count(CASE WHEN is_opened = true THEN channel_id ELSE NULL END) ELSE 1 END as channels_percent_active
    from
        base_data_template
    group by
        zone,
        chain_id
), zones_full_graph as (
    select
        one.zone as source,
        one.counterparty_zone as target,
        one.channels_cnt_open + CASE WHEN two.channels_cnt_open is NULL THEN 0 ELSE two.channels_cnt_open END as channels_cnt_open,
        one.channels_cnt_active + CASE WHEN two.channels_cnt_active is NULL THEN 0 ELSE two.channels_cnt_active END as channels_cnt_active,
        (one.channels_percent_active + CASE WHEN two.channels_percent_active is NULL THEN 0 ELSE two.channels_percent_active END) / 2 as channels_percent_active
    from
        calculate_stats as one
    left join calculate_stats as two
        on one.zone = two.counterparty_zone and one.counterparty_zone = two.zone
)

select
    distinct source as source,
    target as target,
    channels_cnt_open::integer,
    channels_cnt_active::integer,
    channels_percent_active::numeric
from
    (
        select
            source as source,
            target as target,
            channels_cnt_open,
            channels_cnt_active,
            channels_percent_active
        from
            zones_full_graph
        union all
        select
            target as source,
            source as target,
            channels_cnt_open,
            channels_cnt_active,
            channels_percent_active
        from
            zones_full_graph
    ) as double_graph
where
    source < target

$function$;
