
ALTER TABLE "public"."headers" DROP COLUMN "channels_percent_active_period_diff";

ALTER TABLE "public"."headers" DROP COLUMN "channels_percent_active_period";

ALTER TABLE "public"."headers" DROP COLUMN "channels_cnt_active_period_diff";

ALTER TABLE "public"."headers" DROP COLUMN "channels_cnt_active_period";

ALTER TABLE "public"."headers" DROP COLUMN "channels_cnt_open";

ALTER TABLE "public"."headers" DROP COLUMN "relations_cnt_open";

ALTER TABLE "public"."zones_stats" DROP COLUMN "channels_percent_active_period_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "channels_percent_active_period";

ALTER TABLE "public"."zones_stats" DROP COLUMN "channels_cnt_active_period_diff";

ALTER TABLE "public"."zones_stats" DROP COLUMN "channels_cnt_active_period";

ALTER TABLE "public"."zones_stats" DROP COLUMN "channels_cnt_open";

ALTER TABLE "public"."zones_stats" DROP COLUMN "relations_cnt_open";
