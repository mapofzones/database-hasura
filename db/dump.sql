--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Ubuntu 12.2-2.pgdg16.04+1)
-- Dumped by pg_dump version 12.2 (Ubuntu 12.2-2.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: moz_main_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE moz_main_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE moz_main_db OWNER TO postgres;

\connect moz_main_db

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA hdb_catalog;


ALTER SCHEMA hdb_catalog OWNER TO postgres;

--
-- Name: hdb_views; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA hdb_views;


ALTER SCHEMA hdb_views OWNER TO postgres;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: check_violation(text); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.check_violation(msg text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE check_violation USING message=msg;
  END;
$$;


ALTER FUNCTION hdb_catalog.check_violation(msg text) OWNER TO postgres;

--
-- Name: hdb_schema_update_event_notifier(); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.hdb_schema_update_event_notifier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    instance_id uuid;
    occurred_at timestamptz;
    invalidations json;
    curr_rec record;
  BEGIN
    instance_id = NEW.instance_id;
    occurred_at = NEW.occurred_at;
    invalidations = NEW.invalidations;
    PERFORM pg_notify('hasura_schema_update', json_build_object(
      'instance_id', instance_id,
      'occurred_at', occurred_at,
      'invalidations', invalidations
      )::text);
    RETURN curr_rec;
  END;
$$;


ALTER FUNCTION hdb_catalog.hdb_schema_update_event_notifier() OWNER TO postgres;

--
-- Name: inject_table_defaults(text, text, text, text); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        r RECORD;
    BEGIN
      FOR r IN SELECT column_name, column_default FROM information_schema.columns WHERE table_schema = tab_schema AND table_name = tab_name AND column_default IS NOT NULL LOOP
          EXECUTE format('ALTER VIEW %I.%I ALTER COLUMN %I SET DEFAULT %s;', view_schema, view_name, r.column_name, r.column_default);
      END LOOP;
    END;
$$;


ALTER FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) OWNER TO postgres;

--
-- Name: insert_event_log(text, text, text, text, json); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id text;
    payload json;
    session_variables json;
    server_version_num int;
  BEGIN
    id := gen_random_uuid();
    server_version_num := current_setting('server_version_num');
    IF server_version_num >= 90600 THEN
      session_variables := current_setting('hasura.user', 't');
    ELSE
      BEGIN
        session_variables := current_setting('hasura.user');
      EXCEPTION WHEN OTHERS THEN
                  session_variables := NULL;
      END;
    END IF;
    payload := json_build_object(
      'op', op,
      'data', row_data,
      'session_variables', session_variables
    );
    INSERT INTO hdb_catalog.event_log
                (id, schema_name, table_name, trigger_name, payload)
    VALUES
    (id, schema_name, table_name, trigger_name, payload);
    RETURN id;
  END;
$$;


ALTER FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: fn_table_full_stats_for_each; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.fn_table_full_stats_for_each OWNER TO postgres;

--
-- Name: get_full_stats_for_each_zone(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_zone_channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zone_channels (
    zone character varying,
    channels integer
);


ALTER TABLE public.fn_table_zone_channels OWNER TO postgres;

--
-- Name: get_ibc_channels_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_ibc_channels_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_zone_channels
    LANGUAGE sql STABLE
    AS $$

with stats as (
    select distinct
            zone_src,
            zone_dest,
            CASE WHEN txs_cnt is NULL THEN 0 ELSE 1 END  as count
        from 
            ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_ibc_channels_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_txs_rating_txsdiff_ratingdiff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_txs_rating_txsdiff_ratingdiff (
    zone character varying NOT NULL,
    txs integer NOT NULL,
    rating integer NOT NULL,
    txs_diff integer NOT NULL,
    rating_diff integer NOT NULL
);


ALTER TABLE public.fn_table_txs_rating_txsdiff_ratingdiff OWNER TO postgres;

--
-- Name: get_ibc_in_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
        ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_ibc_in_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: get_ibc_out_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
        ibc_tx_hourly_stats
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
                ibc_tx_hourly_stats
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
                ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_ibc_out_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_zone_chart; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zone_chart (
    zone character varying NOT NULL,
    chart json NOT NULL
);


ALTER TABLE public.fn_table_zone_chart OWNER TO postgres;

--
-- Name: get_ibc_tx_activities_on_period(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
            ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_zone_percent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zone_percent (
    zone character varying,
    percent numeric
);


ALTER TABLE public.fn_table_zone_percent OWNER TO postgres;

--
-- Name: get_ibc_tx_percent_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_ibc_tx_percent_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_zone_percent
    LANGUAGE sql STABLE
    AS $$




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

$$;


ALTER FUNCTION public.get_ibc_tx_percent_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: get_ibc_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
        ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_ibc_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_zones_graph; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zones_graph (
    zones jsonb NOT NULL,
    graph jsonb NOT NULL
);


ALTER TABLE public.fn_table_zones_graph OWNER TO postgres;

--
-- Name: get_nodes_stats_with_graph_on_period(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_nodes_stats_with_graph_on_period(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_zones_graph
    LANGUAGE sql STABLE
    AS $$

with zones_full_graph as (
    select distinct
        zone_src as source,
        zone_dest as target
    from 
        ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_nodes_stats_with_graph_on_period(period_in_hours integer, step_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_channels (
    channels integer
);


ALTER TABLE public.fn_table_channels OWNER TO postgres;

--
-- Name: get_total_ibc_channels_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_total_ibc_channels_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_channels
    LANGUAGE sql STABLE
    AS $$

select count(*)::int as count
from (
    select distinct 
        zone_src, 
        zone_dest 
    from 
        ibc_tx_hourly_stats
    where 
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) as a;

$$;


ALTER FUNCTION public.get_total_ibc_channels_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_txs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_txs (
    txs integer
);


ALTER TABLE public.fn_table_txs OWNER TO postgres;

--
-- Name: get_total_ibc_tx_activities_on_period(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
            CASE WHEN sum(ibc_tx_hourly_stats.txs_cnt) is NULL THEN 0 ELSE sum(ibc_tx_hourly_stats.txs_cnt) END AS txs_cnt 
        from hours
        left join ibc_tx_hourly_stats on date_trunc('hour', ibc_tx_hourly_stats.hour) = hours.hour
        group by 1   
    ) as a
) as b
GROUP BY n/step_in_hours
ORDER BY n/step_in_hours;

$$;


ALTER FUNCTION public.get_total_ibc_tx_activities_on_period(period_in_hours integer, step_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_percent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_percent (
    percent numeric
);


ALTER TABLE public.fn_table_percent OWNER TO postgres;

--
-- Name: get_total_ibc_tx_percent_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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
                ibc_tx_hourly_stats
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


ALTER FUNCTION public.get_total_ibc_tx_percent_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: get_total_ibc_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_total_ibc_tx_stats_on_period(period_in_hours integer) RETURNS SETOF public.fn_table_txs
    LANGUAGE sql STABLE
    AS $$
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
$$;


ALTER FUNCTION public.get_total_ibc_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: fn_table_zones_channels_zones_channels_chart_pair; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zones_channels_zones_channels_chart_pair (
    zones_cnt_all integer NOT NULL,
    channels_cnt_all integer NOT NULL,
    zones_cnt_period integer NOT NULL,
    channels_cnt_period integer NOT NULL,
    chart json NOT NULL,
    top_zone_pair jsonb NOT NULL
);


ALTER TABLE public.fn_table_zones_channels_zones_channels_chart_pair OWNER TO postgres;

--
-- Name: get_total_stats(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer) RETURNS SETOF public.fn_table_zones_channels_zones_channels_chart_pair
    LANGUAGE sql STABLE
    AS $$

with graph as (
    select
        zone_src as source,
        zone_dest as target,
        txs_cnt as txs
    from
        ibc_tx_hourly_stats
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
    (select count(*)::int from (select distinct zone_src, zone_dest from ibc_tx_hourly_stats) as all_channels) as channels_cnt_all,
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


ALTER FUNCTION public.get_total_stats(period_in_hours integer, step_in_hours integer) OWNER TO postgres;

--
-- Name: get_total_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.get_total_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: get_tx_stats_on_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.get_tx_stats_on_period(period_in_hours integer) OWNER TO postgres;

--
-- Name: get_tx_stats_on_period_aggregate(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.get_tx_stats_on_period_aggregate(seconds integer) OWNER TO postgres;

--
-- Name: event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.event_invocation_logs (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.event_invocation_logs OWNER TO postgres;

--
-- Name: event_log; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.event_log (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    trigger_name text NOT NULL,
    payload jsonb NOT NULL,
    delivered boolean DEFAULT false NOT NULL,
    error boolean DEFAULT false NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    locked boolean DEFAULT false NOT NULL,
    next_retry_at timestamp without time zone,
    archived boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.event_log OWNER TO postgres;

--
-- Name: event_triggers; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.event_triggers (
    name text NOT NULL,
    type text NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    configuration json,
    comment text
);


ALTER TABLE hdb_catalog.event_triggers OWNER TO postgres;

--
-- Name: hdb_allowlist; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_allowlist (
    collection_name text
);


ALTER TABLE hdb_catalog.hdb_allowlist OWNER TO postgres;

--
-- Name: hdb_check_constraint; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_check_constraint AS
 SELECT (n.nspname)::text AS table_schema,
    (ct.relname)::text AS table_name,
    (r.conname)::text AS constraint_name,
    pg_get_constraintdef(r.oid, true) AS "check"
   FROM ((pg_constraint r
     JOIN pg_class ct ON ((r.conrelid = ct.oid)))
     JOIN pg_namespace n ON ((ct.relnamespace = n.oid)))
  WHERE (r.contype = 'c'::"char");


ALTER TABLE hdb_catalog.hdb_check_constraint OWNER TO postgres;

--
-- Name: hdb_computed_field; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_computed_field (
    table_schema text NOT NULL,
    table_name text NOT NULL,
    computed_field_name text NOT NULL,
    definition jsonb NOT NULL,
    comment text
);


ALTER TABLE hdb_catalog.hdb_computed_field OWNER TO postgres;

--
-- Name: hdb_computed_field_function; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_computed_field_function AS
 SELECT hdb_computed_field.table_schema,
    hdb_computed_field.table_name,
    hdb_computed_field.computed_field_name,
        CASE
            WHEN (((hdb_computed_field.definition -> 'function'::text) ->> 'name'::text) IS NULL) THEN (hdb_computed_field.definition ->> 'function'::text)
            ELSE ((hdb_computed_field.definition -> 'function'::text) ->> 'name'::text)
        END AS function_name,
        CASE
            WHEN (((hdb_computed_field.definition -> 'function'::text) ->> 'schema'::text) IS NULL) THEN 'public'::text
            ELSE ((hdb_computed_field.definition -> 'function'::text) ->> 'schema'::text)
        END AS function_schema
   FROM hdb_catalog.hdb_computed_field;


ALTER TABLE hdb_catalog.hdb_computed_field_function OWNER TO postgres;

--
-- Name: hdb_foreign_key_constraint; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_foreign_key_constraint AS
 SELECT (q.table_schema)::text AS table_schema,
    (q.table_name)::text AS table_name,
    (q.constraint_name)::text AS constraint_name,
    (min(q.constraint_oid))::integer AS constraint_oid,
    min((q.ref_table_table_schema)::text) AS ref_table_table_schema,
    min((q.ref_table)::text) AS ref_table,
    json_object_agg(ac.attname, afc.attname) AS column_mapping,
    min((q.confupdtype)::text) AS on_update,
    min((q.confdeltype)::text) AS on_delete,
    json_agg(ac.attname) AS columns,
    json_agg(afc.attname) AS ref_columns
   FROM ((( SELECT ctn.nspname AS table_schema,
            ct.relname AS table_name,
            r.conrelid AS table_id,
            r.conname AS constraint_name,
            r.oid AS constraint_oid,
            cftn.nspname AS ref_table_table_schema,
            cft.relname AS ref_table,
            r.confrelid AS ref_table_id,
            r.confupdtype,
            r.confdeltype,
            unnest(r.conkey) AS column_id,
            unnest(r.confkey) AS ref_column_id
           FROM ((((pg_constraint r
             JOIN pg_class ct ON ((r.conrelid = ct.oid)))
             JOIN pg_namespace ctn ON ((ct.relnamespace = ctn.oid)))
             JOIN pg_class cft ON ((r.confrelid = cft.oid)))
             JOIN pg_namespace cftn ON ((cft.relnamespace = cftn.oid)))
          WHERE (r.contype = 'f'::"char")) q
     JOIN pg_attribute ac ON (((q.column_id = ac.attnum) AND (q.table_id = ac.attrelid))))
     JOIN pg_attribute afc ON (((q.ref_column_id = afc.attnum) AND (q.ref_table_id = afc.attrelid))))
  GROUP BY q.table_schema, q.table_name, q.constraint_name;


ALTER TABLE hdb_catalog.hdb_foreign_key_constraint OWNER TO postgres;

--
-- Name: hdb_function; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_function (
    function_schema text NOT NULL,
    function_name text NOT NULL,
    configuration jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_function OWNER TO postgres;

--
-- Name: hdb_function_agg; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_function_agg AS
 SELECT (p.proname)::text AS function_name,
    (pn.nspname)::text AS function_schema,
    pd.description,
        CASE
            WHEN (p.provariadic = (0)::oid) THEN false
            ELSE true
        END AS has_variadic,
        CASE
            WHEN ((p.provolatile)::text = ('i'::character(1))::text) THEN 'IMMUTABLE'::text
            WHEN ((p.provolatile)::text = ('s'::character(1))::text) THEN 'STABLE'::text
            WHEN ((p.provolatile)::text = ('v'::character(1))::text) THEN 'VOLATILE'::text
            ELSE NULL::text
        END AS function_type,
    pg_get_functiondef(p.oid) AS function_definition,
    (rtn.nspname)::text AS return_type_schema,
    (rt.typname)::text AS return_type_name,
    (rt.typtype)::text AS return_type_type,
    p.proretset AS returns_set,
    ( SELECT COALESCE(json_agg(json_build_object('schema', q.schema, 'name', q.name, 'type', q.type)), '[]'::json) AS "coalesce"
           FROM ( SELECT pt.typname AS name,
                    pns.nspname AS schema,
                    pt.typtype AS type,
                    pat.ordinality
                   FROM ((unnest(COALESCE(p.proallargtypes, (p.proargtypes)::oid[])) WITH ORDINALITY pat(oid, ordinality)
                     LEFT JOIN pg_type pt ON ((pt.oid = pat.oid)))
                     LEFT JOIN pg_namespace pns ON ((pt.typnamespace = pns.oid)))
                  ORDER BY pat.ordinality) q) AS input_arg_types,
    to_json(COALESCE(p.proargnames, ARRAY[]::text[])) AS input_arg_names,
    p.pronargdefaults AS default_args,
    (p.oid)::integer AS function_oid
   FROM ((((pg_proc p
     JOIN pg_namespace pn ON ((pn.oid = p.pronamespace)))
     JOIN pg_type rt ON ((rt.oid = p.prorettype)))
     JOIN pg_namespace rtn ON ((rtn.oid = rt.typnamespace)))
     LEFT JOIN pg_description pd ON ((p.oid = pd.objoid)))
  WHERE (((pn.nspname)::text !~~ 'pg_%'::text) AND ((pn.nspname)::text <> ALL (ARRAY['information_schema'::text, 'hdb_catalog'::text, 'hdb_views'::text])) AND (NOT (EXISTS ( SELECT 1
           FROM pg_aggregate
          WHERE ((pg_aggregate.aggfnoid)::oid = p.oid)))));


ALTER TABLE hdb_catalog.hdb_function_agg OWNER TO postgres;

--
-- Name: hdb_function_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_function_info_agg AS
 SELECT hdb_function_agg.function_name,
    hdb_function_agg.function_schema,
    row_to_json(( SELECT e.*::record AS e
           FROM ( SELECT hdb_function_agg.description,
                    hdb_function_agg.has_variadic,
                    hdb_function_agg.function_type,
                    hdb_function_agg.return_type_schema,
                    hdb_function_agg.return_type_name,
                    hdb_function_agg.return_type_type,
                    hdb_function_agg.returns_set,
                    hdb_function_agg.input_arg_types,
                    hdb_function_agg.input_arg_names,
                    hdb_function_agg.default_args,
                    (EXISTS ( SELECT 1
                           FROM information_schema.tables
                          WHERE (((tables.table_schema)::name = hdb_function_agg.return_type_schema) AND ((tables.table_name)::name = hdb_function_agg.return_type_name)))) AS returns_table) e)) AS function_info
   FROM hdb_catalog.hdb_function_agg;


ALTER TABLE hdb_catalog.hdb_function_info_agg OWNER TO postgres;

--
-- Name: hdb_permission; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_permission (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    role_name text NOT NULL,
    perm_type text NOT NULL,
    perm_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_permission_perm_type_check CHECK ((perm_type = ANY (ARRAY['insert'::text, 'select'::text, 'update'::text, 'delete'::text])))
);


ALTER TABLE hdb_catalog.hdb_permission OWNER TO postgres;

--
-- Name: hdb_permission_agg; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_permission_agg AS
 SELECT hdb_permission.table_schema,
    hdb_permission.table_name,
    hdb_permission.role_name,
    json_object_agg(hdb_permission.perm_type, hdb_permission.perm_def) AS permissions
   FROM hdb_catalog.hdb_permission
  GROUP BY hdb_permission.table_schema, hdb_permission.table_name, hdb_permission.role_name;


ALTER TABLE hdb_catalog.hdb_permission_agg OWNER TO postgres;

--
-- Name: hdb_primary_key; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_primary_key AS
 SELECT tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    json_agg(constraint_column_usage.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN ( SELECT x.tblschema AS table_schema,
            x.tblname AS table_name,
            x.colname AS column_name,
            x.cstrname AS constraint_name
           FROM ( SELECT DISTINCT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_depend d,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (d.refclassid = ('pg_class'::regclass)::oid) AND (d.refobjid = r.oid) AND (d.refobjsubid = a.attnum) AND (d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = c.oid) AND (c.connamespace = nc.oid) AND (c.contype = 'c'::"char") AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT a.attisdropped))
                UNION ALL
                 SELECT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (nc.oid = c.connamespace) AND (r.oid =
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confrelid
                            ELSE c.conrelid
                        END) AND (a.attnum = ANY (
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confkey
                            ELSE c.conkey
                        END)) AND (NOT a.attisdropped) AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])))) x(tblschema, tblname, colname, cstrname)) constraint_column_usage ON ((((tc.constraint_name)::text = (constraint_column_usage.constraint_name)::text) AND ((tc.table_schema)::text = (constraint_column_usage.table_schema)::text) AND ((tc.table_name)::text = (constraint_column_usage.table_name)::text))))
  WHERE ((tc.constraint_type)::text = 'PRIMARY KEY'::text)
  GROUP BY tc.table_schema, tc.table_name, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_primary_key OWNER TO postgres;

--
-- Name: hdb_query_collection; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_query_collection (
    collection_name text NOT NULL,
    collection_defn jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_query_collection OWNER TO postgres;

--
-- Name: hdb_relationship; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_relationship (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    rel_name text NOT NULL,
    rel_type text,
    rel_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_relationship_rel_type_check CHECK ((rel_type = ANY (ARRAY['object'::text, 'array'::text])))
);


ALTER TABLE hdb_catalog.hdb_relationship OWNER TO postgres;

--
-- Name: hdb_schema_update_event; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_schema_update_event (
    instance_id uuid NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    invalidations json NOT NULL
);


ALTER TABLE hdb_catalog.hdb_schema_update_event OWNER TO postgres;

--
-- Name: hdb_table; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_table (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    configuration jsonb,
    is_system_defined boolean DEFAULT false,
    is_enum boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.hdb_table OWNER TO postgres;

--
-- Name: hdb_table_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_table_info_agg AS
 SELECT schema.nspname AS table_schema,
    "table".relname AS table_name,
    jsonb_build_object('oid', ("table".oid)::integer, 'columns', COALESCE(columns.info, '[]'::jsonb), 'primary_key', primary_key.info, 'unique_constraints', COALESCE(unique_constraints.info, '[]'::jsonb), 'foreign_keys', COALESCE(foreign_key_constraints.info, '[]'::jsonb), 'view_info',
        CASE "table".relkind
            WHEN 'v'::"char" THEN jsonb_build_object('is_updatable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 4) = 4), 'is_insertable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 8) = 8), 'is_deletable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 16) = 16))
            ELSE NULL::jsonb
        END, 'description', description.description) AS info
   FROM ((((((pg_class "table"
     JOIN pg_namespace schema ON ((schema.oid = "table".relnamespace)))
     LEFT JOIN pg_description description ON (((description.classoid = ('pg_class'::regclass)::oid) AND (description.objoid = "table".oid) AND (description.objsubid = 0))))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('name', "column".attname, 'position', "column".attnum, 'type', COALESCE(base_type.typname, type.typname), 'is_nullable', (NOT "column".attnotnull), 'description', col_description("table".oid, ("column".attnum)::integer))) AS info
           FROM ((pg_attribute "column"
             LEFT JOIN pg_type type ON ((type.oid = "column".atttypid)))
             LEFT JOIN pg_type base_type ON (((type.typtype = 'd'::"char") AND (base_type.oid = type.typbasetype))))
          WHERE (("column".attrelid = "table".oid) AND ("column".attnum > 0) AND (NOT "column".attisdropped))) columns ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_build_object('constraint', jsonb_build_object('name', class.relname, 'oid', (class.oid)::integer), 'columns', COALESCE(columns_1.info, '[]'::jsonb)) AS info
           FROM ((pg_index index
             JOIN pg_class class ON ((class.oid = index.indexrelid)))
             LEFT JOIN LATERAL ( SELECT jsonb_agg("column".attname) AS info
                   FROM pg_attribute "column"
                  WHERE (("column".attrelid = "table".oid) AND ("column".attnum = ANY ((index.indkey)::smallint[])))) columns_1 ON (true))
          WHERE ((index.indrelid = "table".oid) AND index.indisprimary)) primary_key ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('name', class.relname, 'oid', (class.oid)::integer)) AS info
           FROM (pg_index index
             JOIN pg_class class ON ((class.oid = index.indexrelid)))
          WHERE ((index.indrelid = "table".oid) AND index.indisunique AND (NOT index.indisprimary))) unique_constraints ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('constraint', jsonb_build_object('name', foreign_key.constraint_name, 'oid', foreign_key.constraint_oid), 'columns', foreign_key.columns, 'foreign_table', jsonb_build_object('schema', foreign_key.ref_table_table_schema, 'name', foreign_key.ref_table), 'foreign_columns', foreign_key.ref_columns)) AS info
           FROM hdb_catalog.hdb_foreign_key_constraint foreign_key
          WHERE ((foreign_key.table_schema = schema.nspname) AND (foreign_key.table_name = "table".relname))) foreign_key_constraints ON (true))
  WHERE ("table".relkind = ANY (ARRAY['r'::"char", 't'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"]));


ALTER TABLE hdb_catalog.hdb_table_info_agg OWNER TO postgres;

--
-- Name: hdb_unique_constraint; Type: VIEW; Schema: hdb_catalog; Owner: postgres
--

CREATE VIEW hdb_catalog.hdb_unique_constraint AS
 SELECT tc.table_name,
    tc.constraint_schema AS table_schema,
    tc.constraint_name,
    json_agg(kcu.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name))
  WHERE ((tc.constraint_type)::text = 'UNIQUE'::text)
  GROUP BY tc.table_name, tc.constraint_schema, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_unique_constraint OWNER TO postgres;

--
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_version (
    hasura_uuid uuid DEFAULT public.gen_random_uuid() NOT NULL,
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL,
    cli_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    console_state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO postgres;

--
-- Name: remote_schemas; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.remote_schemas (
    id bigint NOT NULL,
    name text,
    definition json,
    comment text
);


ALTER TABLE hdb_catalog.remote_schemas OWNER TO postgres;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE; Schema: hdb_catalog; Owner: postgres
--

CREATE SEQUENCE hdb_catalog.remote_schemas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hdb_catalog.remote_schemas_id_seq OWNER TO postgres;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: hdb_catalog; Owner: postgres
--

ALTER SEQUENCE hdb_catalog.remote_schemas_id_seq OWNED BY hdb_catalog.remote_schemas.id;


--
-- Name: blocks_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blocks_log (
    chain_id character varying NOT NULL,
    last_processed_block integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.blocks_log OWNER TO postgres;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.channels (
    source character varying NOT NULL,
    connection_id character varying NOT NULL,
    channel_id character varying NOT NULL,
    opened boolean
);


ALTER TABLE public.channels OWNER TO postgres;

--
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    source character varying NOT NULL,
    client_id character varying NOT NULL,
    chain_id character varying NOT NULL
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: connections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.connections (
    source character varying NOT NULL,
    connection_id character varying NOT NULL,
    client_id character varying NOT NULL
);


ALTER TABLE public.connections OWNER TO postgres;

--
-- Name: fn_table_id; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_id (
    id integer NOT NULL
);


ALTER TABLE public.fn_table_id OWNER TO postgres;

--
-- Name: fn_table_zone_txs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fn_table_zone_txs (
    zone character varying,
    txs integer
);


ALTER TABLE public.fn_table_zone_txs OWNER TO postgres;

--
-- Name: ibc_tx_hourly_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ibc_tx_hourly_stats (
    source character varying NOT NULL,
    zone_src character varying NOT NULL,
    zone_dest character varying NOT NULL,
    hour timestamp without time zone NOT NULL,
    txs_cnt integer NOT NULL
);


ALTER TABLE public.ibc_tx_hourly_stats OWNER TO postgres;

--
-- Name: ibc_tx_hourly_stats_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ibc_tx_hourly_stats_old (
    zone_src character varying NOT NULL,
    zone_dest character varying NOT NULL,
    hour timestamp without time zone NOT NULL,
    txs_cnt integer NOT NULL
);


ALTER TABLE public.ibc_tx_hourly_stats_old OWNER TO postgres;

--
-- Name: total_tx_hourly_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.total_tx_hourly_stats (
    zone character varying NOT NULL,
    hour timestamp without time zone NOT NULL,
    txs_cnt integer NOT NULL
);


ALTER TABLE public.total_tx_hourly_stats OWNER TO postgres;

--
-- Name: ttest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ttest (
    id integer NOT NULL,
    data character varying NOT NULL
);


ALTER TABLE public.ttest OWNER TO postgres;

--
-- Name: ttest_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ttest_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ttest_id_seq OWNER TO postgres;

--
-- Name: ttest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ttest_id_seq OWNED BY public.ttest.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zones (
    name character varying NOT NULL,
    chain_id character varying NOT NULL,
    description character varying,
    is_enabled boolean NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.zones OWNER TO postgres;

--
-- Name: remote_schemas id; Type: DEFAULT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.remote_schemas ALTER COLUMN id SET DEFAULT nextval('hdb_catalog.remote_schemas_id_seq'::regclass);


--
-- Name: ttest id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ttest ALTER COLUMN id SET DEFAULT nextval('public.ttest_id_seq'::regclass);


--
-- Data for Name: event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.event_invocation_logs (id, event_id, status, request, response, created_at) FROM stdin;
\.


--
-- Data for Name: event_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.event_log (id, schema_name, table_name, trigger_name, payload, delivered, error, tries, created_at, locked, next_retry_at, archived) FROM stdin;
\.


--
-- Data for Name: event_triggers; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.event_triggers (name, type, schema_name, table_name, configuration, comment) FROM stdin;
\.


--
-- Data for Name: hdb_allowlist; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_allowlist (collection_name) FROM stdin;
\.


--
-- Data for Name: hdb_computed_field; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_computed_field (table_schema, table_name, computed_field_name, definition, comment) FROM stdin;
\.


--
-- Data for Name: hdb_function; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_function (function_schema, function_name, configuration, is_system_defined) FROM stdin;
public	get_total_ibc_tx_stats_on_period	{}	f
public	get_total_ibc_tx_percent_on_period	{}	f
public	get_total_tx_stats_on_period	{}	f
public	get_tx_stats_on_period	{}	f
public	get_full_stats_for_each_zone	{}	f
public	get_total_ibc_channels_stats_on_period	{}	f
public	get_ibc_tx_stats_on_period	{}	f
public	get_ibc_out_tx_stats_on_period	{}	f
public	get_ibc_in_tx_stats_on_period	{}	f
public	get_ibc_channels_stats_on_period	{}	f
public	get_ibc_tx_activities_on_period	{}	f
public	get_nodes_stats_with_graph_on_period	{}	f
public	get_total_stats	{}	f
public	get_total_ibc_tx_activities_on_period	{}	f
public	get_ibc_tx_percent_on_period	{}	f
\.


--
-- Data for Name: hdb_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_permission (table_schema, table_name, role_name, perm_type, perm_def, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_query_collection; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_query_collection (collection_name, collection_defn, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_relationship; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_relationship (table_schema, table_name, rel_name, rel_type, rel_def, comment, is_system_defined) FROM stdin;
hdb_catalog	hdb_table	detail	object	{"manual_configuration": {"remote_table": {"name": "tables", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	primary_key	object	{"manual_configuration": {"remote_table": {"name": "hdb_primary_key", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	columns	array	{"manual_configuration": {"remote_table": {"name": "columns", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	foreign_key_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_foreign_key_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	relationships	array	{"manual_configuration": {"remote_table": {"name": "hdb_relationship", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	computed_fields	array	{"manual_configuration": {"remote_table": {"name": "hdb_computed_field", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	check_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_check_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	unique_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_unique_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	event_triggers	events	array	{"manual_configuration": {"remote_table": {"name": "event_log", "schema": "hdb_catalog"}, "column_mapping": {"name": "trigger_name"}}}	\N	t
hdb_catalog	event_log	trigger	object	{"manual_configuration": {"remote_table": {"name": "event_triggers", "schema": "hdb_catalog"}, "column_mapping": {"trigger_name": "name"}}}	\N	t
hdb_catalog	event_log	logs	array	{"foreign_key_constraint_on": {"table": {"name": "event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	event_invocation_logs	event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
hdb_catalog	hdb_function_agg	return_table_info	object	{"manual_configuration": {"remote_table": {"name": "hdb_table", "schema": "hdb_catalog"}, "column_mapping": {"return_type_name": "table_name", "return_type_schema": "table_schema"}}}	\N	t
public	zones	total_tx_hourly_stats	array	{"foreign_key_constraint_on": {"table": {"name": "total_tx_hourly_stats", "schema": "public"}, "column": "zone"}}	\N	f
public	zones	ibc_tx_hourly_stats	array	{"foreign_key_constraint_on": {"table": {"name": "ibc_tx_hourly_stats_old", "schema": "public"}, "column": "zone_src"}}	\N	f
public	zones	ibcTxHourlyStatsByZoneDect	array	{"foreign_key_constraint_on": {"table": {"name": "ibc_tx_hourly_stats_old", "schema": "public"}, "column": "zone_dest"}}	\N	f
\.


--
-- Data for Name: hdb_schema_update_event; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_schema_update_event (instance_id, occurred_at, invalidations) FROM stdin;
091f90c9-a653-4f61-b904-94a3dbc7675d	2020-05-13 23:52:22.876819+00	{"metadata":false,"remote_schemas":[]}
\.


--
-- Data for Name: hdb_table; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_table (table_schema, table_name, configuration, is_system_defined, is_enum) FROM stdin;
information_schema	tables	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	schemata	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	views	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	columns	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_table	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_primary_key	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_foreign_key_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_relationship	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_permission_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_computed_field	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_check_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_unique_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_triggers	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_log	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_invocation_logs	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	remote_schemas	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_version	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_query_collection	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_allowlist	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
public	zones	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	total_tx_hourly_stats	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_txs	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zone_txs	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_percent	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zone_percent	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zone_chart	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zone_channels	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_channels	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zones_graph	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_zones_channels_zones_channels_chart_pair	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_txs_rating_txsdiff_ratingdiff	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_full_stats_for_each	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	clients	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	connections	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	channels	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	ibc_tx_hourly_stats_old	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	blocks_log	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	ttest	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	fn_table_id	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	ibc_tx_hourly_stats	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
\.


--
-- Data for Name: hdb_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.hdb_version (hasura_uuid, version, upgraded_on, cli_state, console_state) FROM stdin;
40885083-7417-4c7d-b022-4bfa6dc997cc	31	2020-03-26 08:23:57.52728+00	{}	{"telemetryNotificationShown": true}
\.


--
-- Data for Name: remote_schemas; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

COPY hdb_catalog.remote_schemas (id, name, definition, comment) FROM stdin;
\.


--
-- Data for Name: blocks_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blocks_log (chain_id, last_processed_block) FROM stdin;
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.channels (source, connection_id, channel_id, opened) FROM stdin;
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (source, client_id, chain_id) FROM stdin;
\.


--
-- Data for Name: connections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.connections (source, connection_id, client_id) FROM stdin;
\.


--
-- Data for Name: fn_table_channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_channels (channels) FROM stdin;
\.


--
-- Data for Name: fn_table_full_stats_for_each; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_full_stats_for_each (zone, total_txs, total_ibc_txs, ibc_percent, ibc_tx_out, ibc_tx_in, channels_num, chart, total_txs_rating, total_txs_diff, total_txs_rating_diff, total_ibc_txs_rating, total_ibc_txs_diff, total_ibc_txs_rating_diff, ibc_tx_in_rating, ibc_tx_in_diff, ibc_tx_in_rating_diff, ibc_tx_out_rating, ibc_tx_out_diff, ibc_tx_out_rating_diff, total_ibc_txs_weight, total_txs_weight, ibc_tx_in_weight, ibc_tx_out_weight) FROM stdin;
\.


--
-- Data for Name: fn_table_id; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_id (id) FROM stdin;
\.


--
-- Data for Name: fn_table_percent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_percent (percent) FROM stdin;
\.


--
-- Data for Name: fn_table_txs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_txs (txs) FROM stdin;
\.


--
-- Data for Name: fn_table_txs_rating_txsdiff_ratingdiff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_txs_rating_txsdiff_ratingdiff (zone, txs, rating, txs_diff, rating_diff) FROM stdin;
\.


--
-- Data for Name: fn_table_zone_channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zone_channels (zone, channels) FROM stdin;
\.


--
-- Data for Name: fn_table_zone_chart; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zone_chart (zone, chart) FROM stdin;
\.


--
-- Data for Name: fn_table_zone_percent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zone_percent (zone, percent) FROM stdin;
\.


--
-- Data for Name: fn_table_zone_txs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zone_txs (zone, txs) FROM stdin;
\.


--
-- Data for Name: fn_table_zones_channels_zones_channels_chart_pair; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zones_channels_zones_channels_chart_pair (zones_cnt_all, channels_cnt_all, zones_cnt_period, channels_cnt_period, chart, top_zone_pair) FROM stdin;
\.


--
-- Data for Name: fn_table_zones_graph; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fn_table_zones_graph (zones, graph) FROM stdin;
\.


--
-- Data for Name: ibc_tx_hourly_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ibc_tx_hourly_stats (source, zone_src, zone_dest, hour, txs_cnt) FROM stdin;
\.


--
-- Data for Name: ibc_tx_hourly_stats_old; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ibc_tx_hourly_stats_old (zone_src, zone_dest, hour, txs_cnt) FROM stdin;
\.


--
-- Data for Name: total_tx_hourly_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.total_tx_hourly_stats (zone, hour, txs_cnt) FROM stdin;
\.


--
-- Data for Name: ttest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ttest (id, data) FROM stdin;
2	hi
1	hi
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zones (name, chain_id, description, is_enabled, added_at) FROM stdin;
\.


--
-- Name: remote_schemas_id_seq; Type: SEQUENCE SET; Schema: hdb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('hdb_catalog.remote_schemas_id_seq', 1, false);


--
-- Name: ttest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ttest_id_seq', 2, true);


--
-- Name: event_invocation_logs event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_pkey PRIMARY KEY (id);


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (id);


--
-- Name: event_triggers event_triggers_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_pkey PRIMARY KEY (name);


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_key UNIQUE (collection_name);


--
-- Name: hdb_computed_field hdb_computed_field_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_computed_field
    ADD CONSTRAINT hdb_computed_field_pkey PRIMARY KEY (table_schema, table_name, computed_field_name);


--
-- Name: hdb_function hdb_function_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_function
    ADD CONSTRAINT hdb_function_pkey PRIMARY KEY (function_schema, function_name);


--
-- Name: hdb_permission hdb_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_pkey PRIMARY KEY (table_schema, table_name, role_name, perm_type);


--
-- Name: hdb_query_collection hdb_query_collection_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_query_collection
    ADD CONSTRAINT hdb_query_collection_pkey PRIMARY KEY (collection_name);


--
-- Name: hdb_relationship hdb_relationship_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_pkey PRIMARY KEY (table_schema, table_name, rel_name);


--
-- Name: hdb_table hdb_table_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_table
    ADD CONSTRAINT hdb_table_pkey PRIMARY KEY (table_schema, table_name);


--
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_version
    ADD CONSTRAINT hdb_version_pkey PRIMARY KEY (hasura_uuid);


--
-- Name: remote_schemas remote_schemas_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_name_key UNIQUE (name);


--
-- Name: remote_schemas remote_schemas_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_pkey PRIMARY KEY (id);


--
-- Name: blocks_log blocks_log_hub_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blocks_log
    ADD CONSTRAINT blocks_log_hub_pkey PRIMARY KEY (chain_id);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (source, channel_id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (source, client_id);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (source, connection_id);


--
-- Name: fn_table_id fn_table_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fn_table_id
    ADD CONSTRAINT fn_table_id_pkey PRIMARY KEY (id);


--
-- Name: fn_table_txs_rating_txsdiff_ratingdiff fn_table_txs_rating_txsdiff_ratingdiff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fn_table_txs_rating_txsdiff_ratingdiff
    ADD CONSTRAINT fn_table_txs_rating_txsdiff_ratingdiff_pkey PRIMARY KEY (zone);


--
-- Name: fn_table_zones_graph fn_table_zones_graph_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fn_table_zones_graph
    ADD CONSTRAINT fn_table_zones_graph_pkey PRIMARY KEY (zones);


--
-- Name: ibc_tx_hourly_stats_old ibc_tx_hourly_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ibc_tx_hourly_stats_old
    ADD CONSTRAINT ibc_tx_hourly_stats_pkey PRIMARY KEY (zone_src, zone_dest, hour);


--
-- Name: ibc_tx_hourly_stats ibc_tx_hourly_stats_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ibc_tx_hourly_stats
    ADD CONSTRAINT ibc_tx_hourly_stats_pkey1 PRIMARY KEY (source, zone_src, zone_dest, hour);


--
-- Name: total_tx_hourly_stats total_tx_hourly_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.total_tx_hourly_stats
    ADD CONSTRAINT total_tx_hourly_stats_pkey PRIMARY KEY (zone, hour);


--
-- Name: ttest ttest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ttest
    ADD CONSTRAINT ttest_pkey PRIMARY KEY (id);


--
-- Name: zones zones_chain_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_chain_id_key UNIQUE (chain_id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (name);


--
-- Name: event_invocation_logs_event_id_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_invocation_logs_event_id_idx ON hdb_catalog.event_invocation_logs USING btree (event_id);


--
-- Name: event_log_delivered_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_log_delivered_idx ON hdb_catalog.event_log USING btree (delivered);


--
-- Name: event_log_locked_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_log_locked_idx ON hdb_catalog.event_log USING btree (locked);


--
-- Name: event_log_trigger_name_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_log_trigger_name_idx ON hdb_catalog.event_log USING btree (trigger_name);


--
-- Name: hdb_schema_update_event_one_row; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_schema_update_event_one_row ON hdb_catalog.hdb_schema_update_event USING btree (((occurred_at IS NOT NULL)));


--
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_version_one_row ON hdb_catalog.hdb_version USING btree (((version IS NOT NULL)));


--
-- Name: hdb_schema_update_event hdb_schema_update_event_notifier; Type: TRIGGER; Schema: hdb_catalog; Owner: postgres
--

CREATE TRIGGER hdb_schema_update_event_notifier AFTER INSERT OR UPDATE ON hdb_catalog.hdb_schema_update_event FOR EACH ROW EXECUTE FUNCTION hdb_catalog.hdb_schema_update_event_notifier();


--
-- Name: event_invocation_logs event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.event_log(id);


--
-- Name: event_triggers event_triggers_schema_name_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_schema_name_table_name_fkey FOREIGN KEY (schema_name, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_fkey FOREIGN KEY (collection_name) REFERENCES hdb_catalog.hdb_query_collection(collection_name);


--
-- Name: hdb_computed_field hdb_computed_field_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_computed_field
    ADD CONSTRAINT hdb_computed_field_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_permission hdb_permission_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_relationship hdb_relationship_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: channels channels_source_connection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_source_connection_id_fkey FOREIGN KEY (source, connection_id) REFERENCES public.connections(source, connection_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: clients clients_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_source_fkey FOREIGN KEY (source) REFERENCES public.zones(chain_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: connections connections_source_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_source_client_id_fkey FOREIGN KEY (source, client_id) REFERENCES public.clients(source, client_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: ibc_tx_hourly_stats_old ibc_tx_hourly_stats_zone_dect_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ibc_tx_hourly_stats_old
    ADD CONSTRAINT ibc_tx_hourly_stats_zone_dect_fkey FOREIGN KEY (zone_dest) REFERENCES public.zones(name) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: ibc_tx_hourly_stats_old ibc_tx_hourly_stats_zone_src_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ibc_tx_hourly_stats_old
    ADD CONSTRAINT ibc_tx_hourly_stats_zone_src_fkey FOREIGN KEY (zone_src) REFERENCES public.zones(name) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: total_tx_hourly_stats total_tx_hourly_stats_zone_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.total_tx_hourly_stats
    ADD CONSTRAINT total_tx_hourly_stats_zone_fkey FOREIGN KEY (zone) REFERENCES public.zones(name) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: DATABASE moz_main_db; Type: ACL; Schema: -; Owner: postgres
--

REVOKE CONNECT,TEMPORARY ON DATABASE moz_main_db FROM PUBLIC;


--
-- Name: LANGUAGE plpgsql; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON LANGUAGE plpgsql TO postgres;


--
-- PostgreSQL database dump complete
--

