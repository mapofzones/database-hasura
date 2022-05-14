
ALTER TABLE "public"."nodes_lcd_addrs" ADD COLUMN "added_at" timestamp NOT NULL DEFAULT now();

ALTER TABLE "public"."nodes_rpc_addrs" ADD COLUMN "added_at" timestamp NOT NULL DEFAULT now();
