
ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_hosting_location";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_org_as_name";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_org_as";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_org";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_isp_name";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_timezone_offset";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_timezone";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_lon";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_lat";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_zip";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_district";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_city";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_region_name";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_region";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_country_code";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_country";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_continent_code";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "location_continent";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "ip";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_prioritized";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_hidden";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_lcd_addr_active";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "lcd_addr";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_rpc_addr_active";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "last_block_height";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_recv_connection_active";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "is_send_connection_active";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "connection_duration";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "tx_index";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "moniker";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "version";

ALTER TABLE "public"."zone_nodes" DROP COLUMN "node_id";
