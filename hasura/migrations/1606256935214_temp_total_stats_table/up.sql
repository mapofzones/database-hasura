CREATE TYPE public.temp_t_total_stats as (
    zones_cnt_all integer,
    channels_cnt_all integer,
    zones_cnt_period integer,
    channels_cnt_period integer,
    chart json,
    top_zone_pair jsonb
);
