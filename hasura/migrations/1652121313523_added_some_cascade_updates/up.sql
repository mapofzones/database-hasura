
alter table "public"."active_addresses" drop constraint "active_addresses_zone_hour_period_fkey",
             add constraint "active_addresses_hour_period_zone_fkey"
             foreign key ("hour", "period", "zone")
             references "public"."total_tx_hourly_stats"
             ("hour", "period", "zone") on update cascade on delete restrict;

alter table "public"."ibc_transfer_hourly_cashflow" drop constraint "ibc_transfer_hourly_cashflow_zone_zone_src_zone_dest_hour__fkey",
             add constraint "ibc_transfer_hourly_cashflow_zone_ibc_channel_zone_dest_hour"
             foreign key ("zone", "ibc_channel", "zone_dest", "hour", "period", "zone_src")
             references "public"."ibc_transfer_hourly_stats"
             ("zone", "ibc_channel", "zone_dest", "hour", "period", "zone_src") on update cascade on delete restrict;

alter table "public"."derivatives" drop constraint "derivatives_base_denom_origin_zone_fkey",
             add constraint "derivatives_base_denom_origin_zone_fkey"
             foreign key ("base_denom", "origin_zone")
             references "public"."tokens"
             ("base_denom", "zone") on update cascade on delete restrict;

alter table "public"."token_prices" drop constraint "token_prices_zone_base_denom_fkey",
             add constraint "token_prices_base_denom_zone_fkey"
             foreign key ("base_denom", "zone")
             references "public"."tokens"
             ("base_denom", "zone") on update cascade on delete restrict;
