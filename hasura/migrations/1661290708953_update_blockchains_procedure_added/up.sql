CREATE OR REPLACE PROCEDURE public.update_blockchains()
 LANGUAGE sql
AS $$

INSERT INTO flat.blockchains
SELECT
    network_id,
    name,
    logo_url,
    is_synced,
    website,
    is_mainnet
FROM
    get_blockchains();

$$;
