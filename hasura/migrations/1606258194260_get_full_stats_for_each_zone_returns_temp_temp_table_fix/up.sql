CREATE OR REPLACE FUNCTION public.get_full_stats_for_each_zone(period_in_hours integer, step_in_hours integer)
 RETURNS SETOF temp_t_full_stats_for_each
 LANGUAGE sql
 STABLE
AS $function$
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
), total_ibc_txs as (
	select
		zone,
		txs_current as txs,
		row_number() OVER (Order By txs_current desc)::int AS rating,
		txs_current - txs_previous as txs_diff,
		(row_number() OVER (Order By txs_current) - row_number() OVER (Order By txs_previous))::int as rating_diff
	from current_and_previous_stats
)



, previous_with_current_interval_ibc as (
    select
        zone,
        txs_cnt,
        hour
    from
        total_tx_hourly_stats
    where
        hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => 2*period_in_hours)
), current_interval_stats_ibc as (
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
                previous_with_current_interval_ibc
            where
                hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
        ) as a
        right join zones on zones.name = a.zone
    ) as b
    group by zone
), previous_interval_stats_ibc as (
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
                previous_with_current_interval_ibc
            where
                hour <= (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours =>period_in_hours)
        ) as a
        right join zones on zones.name = a.zone
    ) as b
    group by zone
), current_and_previous_stats_ibc as (
    select 
        current.zone as zone,
        current.txs as txs_current,
        previous.txs as txs_previous
    from current_interval_stats_ibc as current
    left join previous_interval_stats_ibc as previous on current.zone = previous.zone
), total_txs as (
	select
		zone,
		txs_current as txs,
		row_number() OVER (Order By txs_current desc)::int AS rating,
		txs_current - txs_previous as txs_diff,
		(row_number() OVER (Order By txs_current) - row_number() OVER (Order By txs_previous))::int as rating_diff
	from current_and_previous_stats_ibc
)






, current_interval_stats_out_tx as (
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
), previous_interval_stats_out as (
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
), current_and_previous_stats_out as (
    select 
        current.zone as zone,
        current.txs as txs_current,
        previous.txs as txs_previous
    from current_interval_stats_out_tx as current
    left join previous_interval_stats_out as previous on current.zone = previous.zone
), ibc_tx_out as (
	select
		zone,
		txs_current as txs,
		row_number() OVER (Order By txs_current desc)::int AS rating,
		txs_current - txs_previous as txs_diff,
		(row_number() OVER (Order By txs_current) - row_number() OVER (Order By txs_previous))::int as rating_diff
	from current_and_previous_stats_out
)











, current_interval_stats_in as (
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
), previous_interval_stats_in as (
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
), current_and_previous_stats_in as (
    select 
        current.zone as zone,
        current.txs as txs_current,
        previous.txs as txs_previous
    from current_interval_stats as current
    left join previous_interval_stats as previous on current.zone = previous.zone
), ibc_tx_in as (
	select
		zone,
		txs_current as txs,
		row_number() OVER (Order By txs_current desc)::int AS rating,
		txs_current - txs_previous as txs_diff,
		(row_number() OVER (Order By txs_current) - row_number() OVER (Order By txs_previous))::int as rating_diff
	from current_and_previous_stats_in
)



, ibc_stats_current_interval as (
    select
            zone_src,
            zone_dest,
            txs_cnt
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), ibc_tx_percent_on_period as (
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
			ibc_stats_current_interval
		right join zones on zones.name = ibc_stats_current_interval.zone_src
		union all
		select 
			zones.name as zone,
			txs_cnt as txs
		from 
			ibc_stats_current_interval
		right join zones on zones.name = ibc_stats_current_interval.zone_dest
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
)



, stats_ibc_channel as (
    select distinct
            zone_src,
            zone_dest,
            CASE WHEN txs_cnt is NULL THEN 0 ELSE 1 END  as count
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
) , ibc_channels_stats as (
	select 
		zone as zone, 
		sum(count)::int as channels
	from (
		select 
			zones.name as zone,
			CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
		from 
			stats_ibc_channel
		right join zones on zones.name = stats_ibc_channel.zone_src
		union all
		select 
			zones.name as zone,
			CASE WHEN count is NULL THEN 0 ELSE 1 END  as count
		from 
			stats_ibc_channel
		right join zones on zones.name = stats_ibc_channel.zone_dest
	) as a
	group by zone
)












, hours_tx_activities as (
  select generate_series(
    date_trunc('hour', now()) - ((period_in_hours)::text||' hour')::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
), stats_tx_activities as (
    select
            zone_src,
            zone_dest,
            txs_cnt,
            hour
        from 
            ibc_transfer_hourly_stats
        where 
            hour > (CURRENT_TIMESTAMP at time zone 'utc') - make_interval(hours => period_in_hours)
), stats_tx_activities_in_hour as (
    select
        name,
        hour
    from
        hours_tx_activities
    cross join zones
    order by name, hour
), zones_in_stats_tx_activities as (
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats_tx_activities
    right join zones on zones.name = stats_tx_activities.zone_src
    union all
    select 
        zones.name as zone,
        txs_cnt as txs,
        hour
    from 
        stats_tx_activities
    right join zones on zones.name = stats_tx_activities.zone_dest
), union_stats_by_hour as (
    select 
        stats_tx_activities_in_hour.name as zone,
        stats_tx_activities_in_hour.hour as hour,
        CASE WHEN zones_in_stats_tx_activities.txs is NULL THEN 0 ELSE zones_in_stats_tx_activities.txs END AS txs
    from 
        zones_in_stats_tx_activities
    right join stats_tx_activities_in_hour on stats_tx_activities_in_hour.name = zones_in_stats_tx_activities.zone and stats_tx_activities_in_hour.hour = zones_in_stats_tx_activities.hour
), union_indexed_stats_by_hour as (
    select
        zone,
        hour,
        txs,
        row_number() OVER (partition By zone Order By hour) AS n
    from
        union_stats_by_hour
), stats_tx_activities_by_step as (
    select
        zone,
        sum(txs) txs
    from union_indexed_stats_by_hour
    GROUP BY union_indexed_stats_by_hour.zone, n/step_in_hours
    ORDER BY union_indexed_stats_by_hour.zone, n/step_in_hours
), ibc_tx_activities as (
	select 
		zone,
		json_agg(json_build_object('txs', txs)) as chart
	from stats_tx_activities_by_step
	group by zone
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
left join ibc_tx_percent_on_period as ibc_percent on zones.name = ibc_percent.zone
left join ibc_tx_out on zones.name = ibc_tx_out.zone
left join ibc_tx_in on zones.name = ibc_tx_in.zone
left join ibc_channels_stats as channels on zones.name = channels.zone
left join ibc_tx_activities as charts on zones.name = charts.zone;
$function$;
