DROP FUNCTION IF EXISTS public.get_channels_info();

DROP TYPE IF EXISTS public.temp_t_get_channels_info;

CREATE TYPE public.temp_t_get_channels_info as (
    zone character varying,
    counterparty_zone character varying,
    channel character varying,
    counterparty_channel character varying,
    client_id character varying,
    connection_id character varying,
    is_opened bool,
    is_channel_calculable bool,
    is_counterparty_channel_calculable bool
);

CREATE OR REPLACE FUNCTION public.get_channels_info()
 RETURNS SETOF temp_t_get_channels_info
 LANGUAGE sql
 STABLE
AS $function$

with channel_simple_info as (
    select
        channels.zone as zone,
        clients.chain_id as counterparty_zone,
        channels.channel_id as channel,
        channels.counterparty_channel_id as counterparty_channel,
        clients.client_id as client_id,
        connections.connection_id as connection_id,
        channels.is_opened as is_opened
    from
        ibc_channels as channels
    left join ibc_connections as connections
        on channels.zone = connections.zone and channels.connection_id = connections.connection_id
    left join ibc_clients as clients
        on clients.zone = connections.zone and clients.client_id = connections.client_id
)

select
    channel.zone,
    channel.counterparty_zone,
    channel.channel,
    channel.counterparty_channel,
    channel.client_id,
    channel.connection_id,
    channel.is_opened,
    case
        when zone_status.status is null
        then false else true
    end as is_channel_calculable,
    case
        when counterparty_zone_status.status is null or channel.counterparty_channel is NULL or
            (counterparty_zone_status.status is not null and counterparty_channel.counterparty_channel is NULL)
        then false else true
    end as is_counterparty_channel_calculable
from
    channel_simple_info as channel
left join channel_simple_info as counterparty_channel
    on channel.counterparty_zone = counterparty_channel.zone
        and channel.zone = counterparty_channel.counterparty_zone
        and channel.channel = counterparty_channel.counterparty_channel
        and channel.counterparty_channel = counterparty_channel.channel
left join get_zones_statuses() as zone_status
    on channel.zone = zone_status.zone
left join get_zones_statuses() as counterparty_zone_status
    on channel.counterparty_zone = counterparty_zone_status.zone

$function$;
