alter table "public"."ibc_transfer_hourly_cashflow"
           add constraint "ibc_transfer_hourly_cashflow_derivative_denom_zone_fkey"
           foreign key ("derivative_denom", "zone")
           references "public"."derivatives"
           ("full_denom", "zone") on update restrict on delete restrict;
