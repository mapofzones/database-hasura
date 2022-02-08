
ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "ibc_tx_pending";

ALTER TABLE "public"."ft_channels_stats" DROP COLUMN "ibc_tx_pending";

ALTER TABLE "public"."zones_stats" DROP COLUMN "success_rate";

ALTER TABLE "public"."zones_graphs" DROP COLUMN "ibc_cashflow_pending";

ALTER TABLE "public"."zones_graphs" DROP COLUMN "ibc_cashflow";

ALTER TABLE "public"."zones_graphs" DROP COLUMN "ibc_transfers_pending";

ALTER TABLE "public"."zones_graphs" DROP COLUMN "ibc_transfers";

ALTER TABLE "public"."token_prices" DROP COLUMN "sifchain_symbol_price_in_usd";

ALTER TABLE "public"."tokens" DROP COLUMN "sifchain_id";
