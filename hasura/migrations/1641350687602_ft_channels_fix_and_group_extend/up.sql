
alter table "public"."ft_channel_group_stats" rename column "zone_counerparty" to "zone_counterparty";

alter table "public"."ft_channels_stats" rename column "zone_counerparty" to "zone_counterparty";

alter table "public"."ft_channels_stats" rename column "is_zone_counerparty_mainnet" to "is_zone_counterparty_mainnet";

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "is_zone_counterparty_mainnet" boolean NOT NULL;

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "zone_readable_name" varchar NULL;

ALTER TABLE "public"."ft_channel_group_stats" ADD COLUMN "zone_counterparty_readable_name" varchar NULL;
