
DROP FUNCTION IF EXISTS public.get_channels_hourly_stats(timestamp, integer);

DROP TYPE IF EXISTS public.temp_t_get_channels_hourly_stats;

ALTER TABLE "intermediate"."blockchains_hourly_stats" ADD COLUMN "ibc_active_addresses_cnt" int4;
ALTER TABLE "intermediate"."blockchains_hourly_stats" ALTER COLUMN "ibc_active_addresses_cnt" DROP NOT NULL;

ALTER TABLE "intermediate"."channels_hourly_stats" ADD COLUMN "ibc_transfers" int4;
ALTER TABLE "intermediate"."channels_hourly_stats" ALTER COLUMN "ibc_transfers" DROP NOT NULL;

ALTER TABLE "intermediate"."channels_hourly_stats" DROP COLUMN "ibc_transfers_out";

ALTER TABLE "intermediate"."channels_hourly_stats" DROP COLUMN "ibc_transfers_in";
