CREATE TYPE public.temp_t_zones_graphs as (
    source character varying,
    target character varying,
    channels_cnt_open integer,
    channels_cnt_active integer,
    channels_percent_active numeric
);
