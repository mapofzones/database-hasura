CREATE OR REPLACE FUNCTION public.get_chanels_stats()
 RETURNS SETOF temp_t_channels_stats
 LANGUAGE sql
 STABLE
AS $function$

select
    channels.zone as zone,
    connections.client_id as client_id,
    channels.connection_id as connection_id,
    channels.channel_id as channel_id,
    clients.chain_id as zone_counerparty,
    channels.is_opened as is_opened,
    0 as ibc_tx_1d,
    0 as ibc_tx_1d_diff,
    0 as ibc_tx_1d_failed,
    0 as ibc_tx_1d_failed_diff,
    0 as ibc_tx_7d,
    0 as ibc_tx_7d_diff,
    0 as ibc_tx_7d_failed,
    0 as ibc_tx_7d_failed_diff,
    0 as ibc_tx_30d,
    0 as ibc_tx_30d_diff,
    0 as ibc_tx_30d_failed,
    0 as ibc_tx_30d_failed_diff
from
    ibc_channels as channels
inner join ibc_connections as connections
    on channels.zone = connections.zone and channels.connection_id = connections.connection_id
inner join ibc_clients as clients
    on connections.zone = clients.zone and connections.client_id = clients.client_id

$function$;
