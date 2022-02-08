
ALTER TABLE "public"."tokens" ADD COLUMN "sifchain_id" varchar NULL;

ALTER TABLE "public"."token_prices" ADD COLUMN "sifchain_symbol_price_in_usd" numeric NULL;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "ibc_transfers" integer NULL;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "ibc_transfers_pending" integer NULL;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "ibc_cashflow" bigint NULL;

ALTER TABLE "public"."zones_graphs" ADD COLUMN "ibc_cashflow_pending" bigint NULL;

ALTER TABLE "public"."zones_stats" ADD COLUMN "success_rate" numeric NULL;

ALTER TABLE "public"."ft_channels_stats" ADD COLUMN "ibc_tx_pending" integer NULL;

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "ibc_tx_pending" integer NULL;
