
create schema "intermediate";

CREATE TABLE "intermediate"."blockchains_hourly_stats"("network_id" varchar NOT NULL, "timestamp" timestamp NOT NULL, "txs" integer NOT NULL, "ibc_active_addresses_cnt" integer NOT NULL, PRIMARY KEY ("network_id","timestamp") );

CREATE TABLE "intermediate"."channels_hourly_stats"("blockchain" varchar NOT NULL, "channel_id" varchar NOT NULL, "timestamp" timestamp NOT NULL, "ibc_transfers" integer NOT NULL, "ibc_transfers_failed" integer NOT NULL, "ibc_cashflow_in" bigint NOT NULL, "ibc_cashflow_out" bigint NOT NULL, PRIMARY KEY ("blockchain","channel_id","timestamp") );
