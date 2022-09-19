
ALTER TABLE "flat"."blockchain_stats" ALTER COLUMN "ibc_active_addresses_cnt_diff" SET NOT NULL;

ALTER TABLE "flat"."blockchain_stats" ALTER COLUMN "ibc_active_addresses_cnt" SET NOT NULL;
