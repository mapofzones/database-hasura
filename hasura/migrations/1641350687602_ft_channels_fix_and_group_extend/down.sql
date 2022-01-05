
ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "zone_counterparty_readable_name";

ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "zone_readable_name";

ALTER TABLE "public"."ft_channel_group_stats" DROP COLUMN "is_zone_counterparty_mainnet";

alter table "public"."ft_channels_stats" rename column "is_zone_counterparty_mainnet" to "is_zone_counerparty_mainnet";

alter table "public"."ft_channels_stats" rename column "zone_counterparty" to "zone_counerparty";

alter table "public"."ft_channel_group_stats" rename column "zone_counterparty" to "zone_counerparty";
