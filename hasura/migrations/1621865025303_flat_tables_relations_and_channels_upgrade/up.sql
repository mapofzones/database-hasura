
ALTER TABLE "public"."zones_stats" ADD COLUMN "relations_cnt_open" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "channels_cnt_open" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "channels_cnt_active_period" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "channels_cnt_active_period_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "channels_percent_active_period" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."zones_stats" ADD COLUMN "channels_percent_active_period_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "relations_cnt_open" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "channels_cnt_open" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "channels_cnt_active_period" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "channels_cnt_active_period_diff" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "channels_percent_active_period" integer NOT NULL DEFAULT 0;

ALTER TABLE "public"."headers" ADD COLUMN "channels_percent_active_period_diff" integer NOT NULL DEFAULT 0;
