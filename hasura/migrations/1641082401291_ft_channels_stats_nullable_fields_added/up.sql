
ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_label_url" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_counterparty_label_url" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_readable_name" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_counterparty_readable_name" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_label_url2" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_label_url2" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_counterparty_label_url2" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_counterparty_channel_id" DROP NOT NULL;

ALTER TABLE "public"."ft_channels_stats" ALTER COLUMN "zone_website" DROP NOT NULL;
