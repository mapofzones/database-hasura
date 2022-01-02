CREATE TABLE "public"."ft_channel_group_stats"("zone" varchar NOT NULL, "timeframe" integer NOT NULL, "zone_counerparty" varchar NOT NULL, "zone_label_url" varchar NOT NULL, "zone_counterparty_label_url" varchar NOT NULL, "ibc_cashflow_in" bigint NOT NULL, "ibc_cashflow_in_diff" bigint NOT NULL, "ibc_cashflow_out" bigint NOT NULL, "ibc_cashflow_out_diff" bigint NOT NULL, "ibc_tx_success_rate" numeric NOT NULL, "ibc_tx_success_rate_diff" numeric NOT NULL, "ibc_tx" bigint NOT NULL, "ibc_tx_diff" bigint NOT NULL, "ibc_tx_failed" bigint NOT NULL, "ibc_tx_failed_diff" bigint NOT NULL, "is_zone_up_to_date" boolean, "is_zone_counterparty_up_to_date" boolean, PRIMARY KEY ("zone","timeframe") );