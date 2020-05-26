CREATE TABLE public.fn_table_full_stats_for_each (
    zone character varying NOT NULL,
    total_txs integer NOT NULL,
    total_ibc_txs integer NOT NULL,
    ibc_percent numeric NOT NULL,
    ibc_tx_out integer NOT NULL,
    ibc_tx_in integer NOT NULL,
    channels_num integer NOT NULL,
    chart json NOT NULL,
    total_txs_rating integer,
    total_txs_diff integer NOT NULL,
    total_txs_rating_diff integer NOT NULL,
    total_ibc_txs_rating integer NOT NULL,
    total_ibc_txs_diff integer NOT NULL,
    total_ibc_txs_rating_diff integer NOT NULL,
    ibc_tx_in_rating integer NOT NULL,
    ibc_tx_in_diff integer NOT NULL,
    ibc_tx_in_rating_diff integer NOT NULL,
    ibc_tx_out_rating integer NOT NULL,
    ibc_tx_out_diff integer NOT NULL,
    ibc_tx_out_rating_diff integer NOT NULL,
    total_ibc_txs_weight numeric NOT NULL,
    total_txs_weight numeric NOT NULL,
    ibc_tx_in_weight numeric NOT NULL,
    ibc_tx_out_weight numeric NOT NULL
);
CREATE TABLE public.fn_table_zone_channels (
    zone character varying,
    channels integer
);
CREATE TABLE public.fn_table_txs_rating_txsdiff_ratingdiff (
    zone character varying NOT NULL,
    txs integer NOT NULL,
    rating integer NOT NULL,
    txs_diff integer NOT NULL,
    rating_diff integer NOT NULL
);
CREATE TABLE public.fn_table_zone_chart (
    zone character varying NOT NULL,
    chart json NOT NULL
);
CREATE TABLE public.fn_table_zone_percent (
    zone character varying,
    percent numeric
);
CREATE TABLE public.fn_table_zones_graph (
    zones jsonb NOT NULL,
    graph jsonb NOT NULL
);
CREATE TABLE public.fn_table_channels (
    channels integer
);
CREATE TABLE public.fn_table_txs (
    txs integer
);
CREATE TABLE public.fn_table_percent (
    percent numeric
);
CREATE TABLE public.fn_table_zones_channels_zones_channels_chart_pair (
    zones_cnt_all integer NOT NULL,
    channels_cnt_all integer NOT NULL,
    zones_cnt_period integer NOT NULL,
    channels_cnt_period integer NOT NULL,
    chart json NOT NULL,
    top_zone_pair jsonb NOT NULL
);
CREATE TABLE public.blocks_log (
    zone character varying NOT NULL,
    last_processed_block integer DEFAULT 0 NOT NULL,
    last_updated_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.fn_table_id (
    id integer NOT NULL
);
CREATE TABLE public.fn_table_zone_txs (
    zone character varying,
    txs integer
);
CREATE TABLE public.ibc_channel_zone (
    zone character varying NOT NULL,
    chanel_id character varying NOT NULL,
    chain_id character varying NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.ibc_channels (
    zone character varying NOT NULL,
    connection_id character varying NOT NULL,
    channel_id character varying NOT NULL,
    is_opened boolean NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.ibc_clients (
    zone character varying NOT NULL,
    client_id character varying NOT NULL,
    chain_id character varying NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.ibc_connections (
    zone character varying NOT NULL,
    connection_id character varying NOT NULL,
    client_id character varying NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.ibc_transfer_hourly_stats (
    zone character varying NOT NULL,
    zone_src character varying NOT NULL,
    zone_dest character varying NOT NULL,
    hour timestamp without time zone NOT NULL,
    txs_cnt integer NOT NULL,
    period integer NOT NULL
);
CREATE TABLE public.periods (
    period_in_hours integer NOT NULL
);
CREATE TABLE public.total_tx_hourly_stats (
    zone character varying NOT NULL,
    hour timestamp without time zone NOT NULL,
    txs_cnt integer NOT NULL,
    period integer NOT NULL,
    txs_w_ibc_xfer_cnt integer NOT NULL
);
CREATE TABLE public.zone_nodes (
    zone character varying NOT NULL,
    rpc_addr character varying NOT NULL,
    is_alive boolean NOT NULL,
    last_checked_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.zones (
    name character varying NOT NULL,
    chain_id character varying NOT NULL,
    description character varying,
    is_enabled boolean NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL,
    is_caught_up boolean NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);
ALTER TABLE ONLY public.blocks_log
    ADD CONSTRAINT blocks_log_hub_pkey PRIMARY KEY (zone);
ALTER TABLE ONLY public.ibc_channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (zone, channel_id);
ALTER TABLE ONLY public.ibc_connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (zone, connection_id);
ALTER TABLE ONLY public.fn_table_id
    ADD CONSTRAINT fn_table_id_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.fn_table_txs_rating_txsdiff_ratingdiff
    ADD CONSTRAINT fn_table_txs_rating_txsdiff_ratingdiff_pkey PRIMARY KEY (zone);
ALTER TABLE ONLY public.fn_table_zones_graph
    ADD CONSTRAINT fn_table_zones_graph_pkey PRIMARY KEY (zones);
ALTER TABLE ONLY public.ibc_channel_zone
    ADD CONSTRAINT ibc_channel_zone_pkey PRIMARY KEY (zone, chanel_id);
ALTER TABLE ONLY public.ibc_clients
    ADD CONSTRAINT ibc_clients_pkey PRIMARY KEY (zone, client_id);
ALTER TABLE ONLY public.ibc_transfer_hourly_stats
    ADD CONSTRAINT ibc_transfer_hourly_stats_pkey PRIMARY KEY (zone_dest, zone, zone_src, hour, period);
ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (period_in_hours);
ALTER TABLE ONLY public.total_tx_hourly_stats
    ADD CONSTRAINT total_tx_hourly_stats_pkey PRIMARY KEY (zone, hour, period);
ALTER TABLE ONLY public.zone_nodes
    ADD CONSTRAINT zone_nodes_pkey PRIMARY KEY (zone, rpc_addr);
ALTER TABLE ONLY public.zone_nodes
    ADD CONSTRAINT zone_nodes_rpc_addr_key UNIQUE (rpc_addr);
ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (chain_id);
ALTER TABLE ONLY public.blocks_log
    ADD CONSTRAINT blocks_log_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_channels
    ADD CONSTRAINT channels_source_connection_id_fkey FOREIGN KEY (zone, connection_id) REFERENCES public.ibc_connections(zone, connection_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_connections
    ADD CONSTRAINT connections_source_client_id_fkey FOREIGN KEY (zone, client_id) REFERENCES public.ibc_clients(zone, client_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_channel_zone
    ADD CONSTRAINT ibc_channel_zone_chain_id_fkey FOREIGN KEY (chain_id) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_channel_zone
    ADD CONSTRAINT ibc_channel_zone_zone_chanel_id_fkey FOREIGN KEY (zone, chanel_id) REFERENCES public.ibc_channels(zone, channel_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_clients
    ADD CONSTRAINT ibc_clients_chain_id_fkey FOREIGN KEY (chain_id) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_clients
    ADD CONSTRAINT ibc_clients_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_transfer_hourly_stats
    ADD CONSTRAINT ibc_transfer_hourly_stats_period_fkey FOREIGN KEY (period) REFERENCES public.periods(period_in_hours) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_transfer_hourly_stats
    ADD CONSTRAINT ibc_transfer_hourly_stats_zone_dest_fkey FOREIGN KEY (zone_dest) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_transfer_hourly_stats
    ADD CONSTRAINT ibc_transfer_hourly_stats_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.ibc_transfer_hourly_stats
    ADD CONSTRAINT ibc_transfer_hourly_stats_zone_src_fkey FOREIGN KEY (zone_src) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.total_tx_hourly_stats
    ADD CONSTRAINT total_tx_hourly_stats_period_fkey FOREIGN KEY (period) REFERENCES public.periods(period_in_hours) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.total_tx_hourly_stats
    ADD CONSTRAINT total_tx_hourly_stats_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.zone_nodes
    ADD CONSTRAINT zone_nodes_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
CREATE FUNCTION public.get_ibc_channels_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_zone_channels
    LANGUAGE sql STABLE
    AS $$
with stats as (
    select distinct
            zone_src,
            zone_dest,
            CASE WHEN txs_cnt is NULL THEN 0 ELSE 1 END  as count
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
)
select 
    zone as zone, 
    sum(count)::int as channels
from (
    select 
        zones.name as zone,
        CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
    from 
        stats
    right join zones on zones.name = stats.zone_src
    union all
    select 
        zones.name as zone,
        CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
    from 
        stats
    right join zones on zones.name = stats.zone_dest
) as a
group by zone;
$$;
CREATE FUNCTION public.get_ibc_in_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs_rating_txsdiff_ratingdiff
    LANGUAGE sql STABLE
    AS $$
with previous_with_current_interval as (
    select
        zone_src,
        zone_dest,
        txs_cnt,
        hour
    from 
        ibc_transfer_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_dest
    ) as a
    group by zone
), previous_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_dest
    ) as a
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
$$;
CREATE FUNCTION public.get_ibc_out_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs_rating_txsdiff_ratingdiff
    LANGUAGE sql STABLE
    AS $$
with previous_with_current_interval as (
    select
        zone_src,
        zone_dest,
        txs_cnt,
        hour
    from 
        ibc_transfer_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                ibc_transfer_hourly_stats
            where 
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_src
    ) as a
    group by zone
), previous_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                ibc_transfer_hourly_stats
            where 
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_src
    ) as a
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
$$;
CREATE FUNCTION public.get_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_zone_chart
    LANGUAGE sql STABLE
    AS $$
with hours as (
  select generate_series(
    date_trunc('hour', now()) - ((period_in_hours)::text||' hour')::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
), stats as (
    select
            zone_src,
            zone_dest,
            txs_cnt,
            hour
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), stats_in_hour as (
    select
        name,
        hour
    from
        hours
    cross join zones
    order by name, hour
), zones_in_stats as (
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats
    right join zones on zones.name = stats.zone_src
    union all
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats
    right join zones on zones.name = stats.zone_dest
), union_stats_by_hour as (
    select 
        stats_in_hour.name as zone,
        stats_in_hour.hour as hour,
        CASE WHEN zones_in_stats.txs is NULL THEN 0 ELSE zones_in_stats.txs END AS txs
    from 
        zones_in_stats
    right join stats_in_hour on stats_in_hour.name = zones_in_stats.zone and stats_in_hour.hour = zones_in_stats.hour
), union_indexed_stats_by_hour as (
    select
        zone,
        hour,
        txs,
        row_number() OVER (partition By zone Order By hour) AS n
    from
        union_stats_by_hour
), stats_by_step as (
    select
        zone,
        sum(txs) txs
    from union_indexed_stats_by_hour
    GROUP BY union_indexed_stats_by_hour.zone, n/step_in_hours
    ORDER BY union_indexed_stats_by_hour.zone, n/step_in_hours
)
select 
    zone,
    json_agg(json_build_object('txs', txs)) as chart
from stats_by_step
group by zone;
$$;
CREATE FUNCTION public.get_ibc_tx_percent_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_zone_percent
    LANGUAGE sql STABLE
    AS $$
with stats as (
    select
            zone_src,
            zone_dest,
            txs_cnt
        from 
            ibc_transfer_hourly_stats
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
$$;
CREATE FUNCTION public.get_ibc_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs_rating_txsdiff_ratingdiff
    LANGUAGE sql STABLE
    AS $$
with previous_with_current_interval as (
    select
        zone_src,
        zone_dest,
        txs_cnt,
        hour
    from 
        ibc_transfer_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_src
        union all
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_dest
    ) as a
    group by zone
), previous_interval_stats as (
    select 
        zone as zone, 
        CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
    from (
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_src
        union all
        select 
            zones.name as zone,
            txs_cnt as txs
        from (
            select
                zone_src,
                zone_dest,
                txs_cnt
            from 
                previous_with_current_interval
            where 
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as stats
        right join zones on zones.name = stats.zone_dest
    ) as a
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
$$;
CREATE FUNCTION public.get_total_ibc_channels_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_channels
    LANGUAGE sql STABLE
    AS $$
select count(*)::int as count
from (
    select distinct 
        zone_src, 
        zone_dest 
    from 
        ibc_transfer_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) as a;
$$;
CREATE FUNCTION public.get_total_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_txs
    LANGUAGE sql STABLE
    AS $$
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
$$;
CREATE FUNCTION public.get_total_ibc_tx_percent_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_percent
    LANGUAGE sql STABLE
    AS $$
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
$$;
CREATE FUNCTION public.get_total_ibc_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs
    LANGUAGE sql STABLE
    AS $$
select 
    CASE WHEN sum(txs)::int is NULL THEN 0 ELSE sum(txs)::int  END as txs
from (
    select
            txs_cnt as txs
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) as a
$$;
CREATE FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_zones_channels_zones_channels_chart_pair
    LANGUAGE sql STABLE
    AS $$
with graph as (
    select
        zone_src as source,
        zone_dest as target,
        txs_cnt as txs
    from
        ibc_transfer_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), active_zones as (
    select distinct
        source as zone
    from
        graph
    union all
    select distinct
        target as zone
    from
        graph
), pairs as (
    select
        source,
        target,
        txs
    from (
        select
            source,
            target,
            txs
        from
            graph
        union all
        select
            target as source,
            source as target,
            txs
        from
            graph
        ) as dsf
    where source < target
), top_pair as (
    select distinct
        source,
        target,
        sum(txs) over (partition by source, target) as ibc
    from 
        pairs
    order by ibc desc
    limit 1
), top_pair_stats as (
    select distinct
        source,
        target,
        ibc as ibc,
        (select case  when sum(txs)::int is null then 0 else sum(txs)::int end from graph where top_pair.source=graph.source and top_pair.target=graph.target) as source_to_target_txs,
        (select case  when sum(txs)::int is null then 0 else sum(txs)::int end from graph where top_pair.source=graph.target and top_pair.target=graph.source) as target_to_source_txs
    from 
        top_pair
), top_pair_json as (
    select
        case  when json_agg(json_build_object('source', source, 'target', target, 'ibc', ibc, 'source_to_target_txs', source_to_target_txs, 'target_to_source_txs', target_to_source_txs)) is null then '[]' 
        else json_agg(json_build_object('source', source, 'target', target, 'ibc', ibc, 'source_to_target_txs', source_to_target_txs, 'target_to_source_txs', target_to_source_txs))::jsonb end as top_zone_pair
    from 
        top_pair_stats as pair
)
select
    (select count(name)::int as zones_cnt_all from zones) as zones_cnt_all,
    (select count(*)::int from (select distinct zone_src, zone_dest from ibc_transfer_hourly_stats) as all_channels) as channels_cnt_all,
    (select count(active_zones.zone)::int from (select distinct zone from active_zones) as active_zones) as zones_cnt_period,
    ibc_channels.channels as channels_cnt_period,
    ibc_chart.chart as chart,
    (select top_zone_pair from top_pair_json) as top_zone_pair
from
    get_total_ibc_channels_stats_on_period(period_in_hours) as ibc_channels
cross join (
    select 
        json_agg(ibc_chart) chart
    from 
        get_total_ibc_tx_activities_on_period(period_in_hours, step_in_hours) as ibc_chart
    ) as ibc_chart
limit 1
$$;
CREATE FUNCTION public.get_total_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs
    LANGUAGE sql STABLE
    AS $$
select
  CASE WHEN sum(txs_cnt) :: int is NULL THEN 0 ELSE sum(txs_cnt) :: int END  as txs
from
  total_tx_hourly_stats
where
  hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours) 
$$;
CREATE FUNCTION public.get_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs_rating_txsdiff_ratingdiff
    LANGUAGE sql STABLE
    AS $$
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
$$;
CREATE FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_full_stats_for_each
    LANGUAGE sql STABLE
    AS $$
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
$$;
CREATE FUNCTION public.get_nodes_stats_with_graph_on_period(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_zones_graph
    LANGUAGE sql STABLE
    AS $$
with zones_full_graph as (
    select distinct
        zone_src as source,
        zone_dest as target
    from 
        ibc_transfer_hourly_stats
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
$$;
CREATE FUNCTION public.get_tx_stats_on_period_aggregate(seconds integer) RETURNS SETOF integer
    LANGUAGE sql STABLE
    AS $$
    select
        sum(txs_cnt)::int
    from 
        total_tx_hourly_stats 
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(secs => seconds);
$$;
