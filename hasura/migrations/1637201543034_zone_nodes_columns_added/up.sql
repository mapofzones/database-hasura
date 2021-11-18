
ALTER TABLE "public"."zone_nodes" ADD COLUMN "node_id" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "version" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "moniker" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "tx_index" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "connection_duration" bigint NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_send_connection_active" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_recv_connection_active" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "last_block_height" integer NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_rpc_addr_active" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "lcd_addr" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_lcd_addr_active" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_hidden" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_prioritized" boolean NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "ip" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_continent" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_continent_code" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_country" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_country_code" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_region" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_region_name" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_city" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_district" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_zip" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_lat" float4 NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_lon" float4 NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_timezone" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_timezone_offset" integer NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_isp_name" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_org" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_org_as" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "location_org_as_name" varchar NULL;

ALTER TABLE "public"."zone_nodes" ADD COLUMN "is_hosting_location" boolean NULL;
