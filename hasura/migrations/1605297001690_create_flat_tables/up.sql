CREATE TABLE "public"."headers" (
    "timeframe" integer NOT NULL,
    "zones_cnt_all" integer NOT NULL,
    "channels_cnt_all" integer NOT NULL,
    "zones_cnt_period" integer NOT NULL,
    "channels_cnt_period" integer NOT NULL,
    "chart" jsonb NOT NULL,
    "top_zone_pair" jsonb NOT NULL,
    PRIMARY KEY ("timeframe")
);

CREATE TABLE "public"."zones_graphs" (
    "timeframe" integer NOT NULL,
    "source" varchar NOT NULL,
    "target" varchar NOT NULL,
    PRIMARY KEY ("timeframe","source","target")
);

CREATE TABLE "public"."zones_stats" (
    "timeframe" integer NOT NULL,
    "zone" varchar NOT NULL,
    "chart" jsonb NOT NULL,
    "ibc_tx_in" integer NOT NULL,
    "total_txs" integer NOT NULL,
    "ibc_tx_out" integer NOT NULL,
    "ibc_percent" integer NOT NULL,
    "channels_num" integer NOT NULL,
    "total_ibc_txs" integer NOT NULL,
    "ibc_tx_in_diff" integer NOT NULL,
    "total_txs_diff" integer NOT NULL,
    "ibc_tx_out_diff" integer NOT NULL,
    "ibc_tx_in_rating" integer NOT NULL,
    "ibc_tx_in_weight" numeric NOT NULL,
    "total_txs_rating" integer NOT NULL,
    "total_txs_weight" numeric NOT NULL,
    "ibc_tx_out_rating" integer NOT NULL,
    "ibc_tx_out_weight" numeric NOT NULL,
    "total_ibc_txs_diff" integer NOT NULL,
    "total_ibc_txs_rating" integer NOT NULL,
    "total_ibc_txs_weight" numeric NOT NULL,
    "ibc_tx_in_rating_diff" integer NOT NULL,
    "total_txs_rating_diff" integer NOT NULL,
    "ibc_tx_out_rating_diff" integer NOT NULL,
    "total_ibc_txs_rating_diff" integer NOT NULL,
    PRIMARY KEY ("timeframe","zone")
);
