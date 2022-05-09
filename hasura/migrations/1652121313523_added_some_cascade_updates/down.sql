
alter table "public"."token_prices" drop constraint "token_prices_base_denom_zone_fkey",
          add constraint "token_prices_zone_base_denom_fkey"
          foreign key ("zone", "base_denom")
          references "public"."tokens"
          ("zone", "base_denom")
          on update restrict
          on delete restrict;

alter table "public"."derivatives" drop constraint "derivatives_base_denom_origin_zone_fkey",
          add constraint "derivatives_base_denom_origin_zone_fkey"
          foreign key ("origin_zone", "base_denom")
          references "public"."tokens"
          ("zone", "base_denom")
          on update restrict
          on delete restrict;

alter table "public"."ibc_transfer_hourly_cashflow" drop constraint "ibc_transfer_hourly_cashflow_zone_ibc_channel_zone_dest_hour",
          add constraint "ibc_transfer_hourly_cashflow_zone_zone_src_zone_dest_hour__fkey"
          foreign key ("zone_src", "period", "hour", "zone_dest", "ibc_channel", "zone")
          references "public"."ibc_transfer_hourly_stats"
          ("zone_src", "period", "hour", "zone_dest", "ibc_channel", "zone")
          on update restrict
          on delete restrict;

alter table "public"."active_addresses" drop constraint "active_addresses_hour_period_zone_fkey",
          add constraint "active_addresses_zone_hour_period_fkey"
          foreign key ("zone", "period", "hour")
          references "public"."total_tx_hourly_stats"
          ("zone", "period", "hour")
          on update restrict
          on delete restrict;
