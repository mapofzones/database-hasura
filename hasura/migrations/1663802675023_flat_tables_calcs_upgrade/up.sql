CREATE OR REPLACE PROCEDURE public.update_flat_tables_calcs(request_timestamp timestamp)
 LANGUAGE sql
AS $$

-- truncate intermediate
TRUNCATE TABLE intermediate.blockchains_hourly_stats;
TRUNCATE TABLE intermediate.channels_hourly_stats;

-- delete flat
DELETE FROM flat.blockchain_relations;
DELETE FROM flat.blockchain_tf_charts;
DELETE FROM flat.blockchain_tf_switched_charts;
DELETE FROM flat.blockchain_switched_stats;
DELETE FROM flat.blockchain_stats;
DELETE FROM flat.channels_stats;
DELETE FROM flat.token_charts;
UPDATE flat.blockchains SET base_token = NULL;
DELETE FROM flat.tokens;
DELETE FROM flat.blockchains;
DELETE FROM flat.total_tf_switched_charts;

-- intermediate
CALL
  update_blockchains_hourly_stats(request_timestamp, 720);
CALL
  update_channels_hourly_stats(request_timestamp, 720);

-- flat
CALL
  update_blockchains();

CALL
  update_blockchain_stats(request_timestamp, 24);
CALL
  update_blockchain_stats(request_timestamp, 168);
CALL
  update_blockchain_stats(request_timestamp, 720);

CALL
  update_channels_stats(request_timestamp, 24);
CALL
  update_channels_stats(request_timestamp, 168);
CALL
  update_channels_stats(request_timestamp, 720);

CALL
    update_blockchain_relations(request_timestamp, 24);
CALL
    update_blockchain_relations(request_timestamp, 168);
CALL
    update_blockchain_relations(request_timestamp, 720);

CALL
    update_tokens();

CALL
    update_blockchains_extention();

CALL
    update_blockchain_switched_stats();

CALL
    update_token_charts(request_timestamp);


CALL
    update_blockchain_tf_charts(request_timestamp);
CALL
    update_blockchain_tf_switched_charts(request_timestamp);
CALL
    update_blockchain_tf_switched_charts_cashflow(request_timestamp);
CALL
    update_total_tf_switched_charts_cashflow(request_timestamp);
CALL
    update_total_tf_switched_charts_trading_volume();

$$;
