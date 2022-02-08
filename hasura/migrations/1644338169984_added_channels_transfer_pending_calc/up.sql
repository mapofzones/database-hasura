DROP FUNCTION IF EXISTS public.get_ft_chanels_stats(integer, integer, boolean);

DROP TYPE IF EXISTS public.temp_t_ft_channels_stats;

CREATE TYPE public.temp_t_ft_channels_stats as (
    zone character varying,
    client_id character varying,
    connection_id character varying,
    channel_id character varying,
    timeframe integer,
    zone_counerparty character varying,
    is_opened boolean,
    ibc_tx integer,
    ibc_tx_diff integer,
    ibc_tx_failed integer,
    ibc_tx_failed_diff integer,
    zone_label_url character varying,
    zone_counterparty_label_url character varying,
    zone_readable_name character varying,
    zone_counterparty_readable_name character varying,
    is_zone_counerparty_mainnet boolean,
    zone_label_url2 character varying,
    zone_counterparty_label_url2 character varying,
    zone_counterparty_channel_id character varying,
    zone_website character varying,
    ibc_cashflow_in bigint,
    ibc_cashflow_in_diff bigint,
    ibc_cashflow_out bigint,
    ibc_cashflow_out_diff bigint,
    ibc_tx_success_rate numeric,
    ibc_tx_success_rate_diff numeric,
    ibc_cashflow_in_pending bigint,
    ibc_cashflow_out_pending bigint,
    ibc_tx_pending integer
);

CREATE OR REPLACE FUNCTION public.get_ft_chanels_stats(period_in_hours integer, step_in_hours integer, is_mainnet_only boolean)
 RETURNS SETOF temp_t_ft_channels_stats
 LANGUAGE sql
 STABLE
AS $function$

select
    transfers_stats.zone as zone,
    transfers_stats.client_id as client_id,
    transfers_stats.connection_id as connection_id,
    transfers_stats.channel as channel_id,
    period_in_hours as timeframe,
    transfers_stats.counterparty_zone as zone_counerparty,
    transfers_stats.is_opened as is_opened,
    transfers_stats.tx_in + transfers_stats.tx_out as ibc_tx,
    transfers_stats.tx_in_diff + transfers_stats.tx_out_diff as ibc_tx_diff,
    transfers_stats.failed_tx as ibc_tx_failed,
    transfers_stats.failed_tx_diff as ibc_tx_failed_diff,
    zones_current.zone_label_url as zone_label_url,
    zones_counerparty.zone_label_url as zone_counterparty_label_url,
    zones_current.name as zone_readable_name,
    zones_counerparty.name as zone_counterparty_readable_name,
    zones_counerparty.is_mainnet as is_zone_counerparty_mainnet,
    zones_current.zone_label_url2 as zone_label_url2,
    zones_counerparty.zone_label_url2 as zone_counterparty_label_url2,
    transfers_stats.counterparty_channel as zone_counterparty_channel_id,
    zones_current.website as zone_website,
    coalesce(cashflow.cashflow_in, 0) as ibc_cashflow_in,
    coalesce(cashflow.cashflow_in_diff, 0) as ibc_cashflow_in_diff,
    coalesce(cashflow.cashflow_out, 0) as ibc_cashflow_out,
    coalesce(cashflow.cashflow_out_diff, 0) as ibc_cashflow_out_diff,
    (100.0 * ((transfers_stats.tx_in + transfers_stats.tx_out)::numeric /
        case
            when (transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx) = 0 then 1
            else transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx
        end))::numeric as ibc_tx_success_rate,
    (100.0 * ((transfers_stats.tx_in + transfers_stats.tx_out)::numeric /
        case
            when (transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx) = 0 then 1
            else transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx
        end))::numeric -
            (100.0 * ((transfers_stats.tx_in + transfers_stats.tx_out - transfers_stats.tx_in_diff - transfers_stats.tx_out_diff)::numeric /
                case
                    when (transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx - transfers_stats.tx_in_diff - transfers_stats.tx_out_diff - transfers_stats.failed_tx_diff) = 0 then 1
                    else transfers_stats.tx_in + transfers_stats.tx_out + transfers_stats.failed_tx - transfers_stats.tx_in_diff - transfers_stats.tx_out_diff - transfers_stats.failed_tx_diff
                end
            ))::numeric as ibc_tx_success_rate_diff,
    coalesce(cashflow.cashflow_in_pending, 0) as ibc_cashflow_in_pending,
    coalesce(cashflow.cashflow_out_pending, 0)::bigint as ibc_cashflow_out_pending,
    coalesce(transfers_stats.tx_in_pending + transfers_stats.tx_out_pending, 0)::integer as ibc_tx_pending
from
    get_channels_transfers_stats(period_in_hours, step_in_hours, is_mainnet_only) as transfers_stats
inner join zones as zones_current
    on zones_current.chain_id = transfers_stats.zone
inner join zones as zones_counerparty
    on zones_counerparty.chain_id = transfers_stats.counterparty_zone
left join get_channels_cashflow_stats(period_in_hours, step_in_hours, is_mainnet_only) as cashflow
    on transfers_stats.zone = cashflow.zone and transfers_stats.channel = cashflow.channel

$function$;
