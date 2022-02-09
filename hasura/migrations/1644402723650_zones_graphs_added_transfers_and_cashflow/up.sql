DROP FUNCTION IF EXISTS public.get_zones_graphs(integer);

DROP FUNCTION IF EXISTS public.get_zones_graphs(integer, integer, boolean);

DROP TYPE IF EXISTS public.temp_t_zones_graphs;

CREATE TYPE public.temp_t_zones_graphs as (
    source character varying,
    target character varying,
    channels_cnt_open integer,
    channels_cnt_active integer,
    channels_percent_active numeric,
    is_mainnet boolean,
    ibc_transfers integer,
    ibc_transfers_pending integer,
    ibc_cashflow bigint,
    ibc_cashflow_pending bigint
);

CREATE OR REPLACE FUNCTION public.get_zones_graphs(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_zones_graphs
 LANGUAGE sql
 STABLE
AS $function$

with transfers as (
    select
        zone,
        ibc_channel,
        hour,
        txs_cnt
    from
        ibc_transfer_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), base_data_template as (
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
    left join transfers
        on transfers.ibc_channel = channels.channel_id and transfers.zone = channels.zone
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
        count(CASE WHEN txs > 0 THEN txs ELSE NULL END) as channels_cnt_active
    from
        base_data_template
    group by
        zone,
        chain_id
), zones_full_graph as (
    select 
        source,
        target,
        channels_cnt_open,
        channels_cnt_active,
        100 * (sum(channels_cnt_active)::numeric / CASE WHEN sum(channels_cnt_open) = 0 THEN 1 ELSE sum(channels_cnt_open) END) as channels_percent_active
    from (
        select
            one.zone as source,
            one.counterparty_zone as target,
            one.channels_cnt_open + CASE WHEN two.channels_cnt_open is NULL THEN 0 ELSE two.channels_cnt_open END as channels_cnt_open,
            one.channels_cnt_active + CASE WHEN two.channels_cnt_active is NULL THEN 0 ELSE two.channels_cnt_active END as channels_cnt_active
        from
            calculate_stats as one
        left join calculate_stats as two
            on one.zone = two.counterparty_zone and one.counterparty_zone = two.zone
    ) as stats
    group by
        source,
        target,
        channels_cnt_open,
        channels_cnt_active
)
, valuable_graph as (
    select distinct
        source as source,
        target as target,
        channels_cnt_open::integer,
        channels_cnt_active::integer,
        channels_percent_active::numeric,
        CASE WHEN zones_source.is_mainnet = true THEN zones_target.is_mainnet ELSE false END as is_mainnet
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
    inner join zones as zones_source
        on zones_source.chain_id = source
    inner join zones as zones_target
        on zones_target.chain_id = target
    where
        source < target
)
, transfers_stats as (
    select
        zone,
        counterparty_zone,
        sum(tx_in) as tx_in,
        sum(tx_in_pending) as tx_in_pending,
        sum(tx_out) as tx_out,
        sum(tx_out_pending) as tx_out_pending
    from
        get_channels_transfers_stats(period_in_hours, step_in_hours, is_mainnet_only)
    group by
        zone,
        counterparty_zone
)
, cashflow_stats as (
    select
        zone,
        counterparty_zone,
        sum(cashflow_in) as cashflow_in,
        sum(cashflow_in_pending) as cashflow_in_pending,
        sum(cashflow_out) as cashflow_out,
        sum(cashflow_out_pending) as cashflow_out_pending
    from
        get_channels_cashflow_stats(period_in_hours, step_in_hours, is_mainnet_only)
    group by
        zone,
        counterparty_zone
)

select
    graph.source,
    graph.target,
    graph.channels_cnt_open,
    graph.channels_cnt_active,
    graph.channels_percent_active,
    graph.is_mainnet,
    coalesce(tr.tx_in + tr.tx_out, cp_tr.tx_in + cp_tr.tx_out, 0)::integer as ibc_transfers,
    coalesce(tr.tx_in_pending + tr.tx_out_pending, cp_tr.tx_in_pending + cp_tr.tx_out_pending, 0)::integer as ibc_transfers_pending,
    coalesce(cf.cashflow_in + cf.cashflow_out, cp_cf.cashflow_in + cp_cf.cashflow_out, 0)::bigint as ibc_cashflow,
    coalesce(cf.cashflow_in_pending + cf.cashflow_out_pending, cp_cf.cashflow_in_pending + cp_cf.cashflow_out_pending, 0)::bigint as ibc_cashflow_pending
from
    valuable_graph as graph
left join transfers_stats as tr
    on graph.source = tr.zone and graph.target = tr.counterparty_zone
left join transfers_stats as cp_tr
          on graph.target = cp_tr.zone and graph.source = cp_tr.counterparty_zone
left join cashflow_stats as cf
          on graph.source = cf.zone and graph.target = cf.counterparty_zone
left join cashflow_stats as cp_cf
          on graph.target = cp_cf.zone and graph.source = cp_cf.counterparty_zone
$function$;
