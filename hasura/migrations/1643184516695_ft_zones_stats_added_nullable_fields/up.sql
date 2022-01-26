
ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_transfers_weight" DROP NOT NULL;

ALTER TABLE "public"."zones_stats" ALTER COLUMN "ibc_transfers_mainnet_weight" DROP NOT NULL;
