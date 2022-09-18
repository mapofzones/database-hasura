CREATE OR REPLACE PROCEDURE public.update_blockchains_extention()
 LANGUAGE sql
AS $$
    
UPDATE
    flat.blockchains
SET
    base_token = dataset.base_token,
    inflation = dataset.inflation,
    staking_apr = dataset.staking_apr,
    unbonding_period = dataset.unbonding_period,
    bonded_tokens = dataset.bonded_tokens,
    bonded_tokens_percent = dataset.bonded_tokens_percent,
    validators_cnt = dataset.validators_cnt,
    nodes_cnt = dataset.nodes_cnt
FROM
    flat.blockchains as bh
INNER JOIN public.get_blockchains_extention() as dataset
    ON bh.network_id = dataset.network_id
INNER JOIN flat.tokens as tk
    ON tk.blockchain = bh.network_id and tk.denom = dataset.base_token
WHERE
    bh.is_mainnet = true
    and flat.blockchains.network_id = bh.network_id

$$;
