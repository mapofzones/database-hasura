
ALTER TABLE "flat"."blockchain_stats" ALTER COLUMN "ibc_active_addresses_cnt" DROP NOT NULL;

ALTER TABLE "flat"."blockchain_stats" ALTER COLUMN "ibc_active_addresses_cnt_diff" DROP NOT NULL;
