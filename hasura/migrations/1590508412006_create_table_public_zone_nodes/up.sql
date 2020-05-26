CREATE TABLE "public"."zone_nodes"("zone" varchar NOT NULL, "rpc_addr" varchar NOT NULL, "is_alive" bool NOT NULL, "last_checked_at" timestamp NOT NULL DEFAULT now(), PRIMARY KEY ("zone","rpc_addr") , FOREIGN KEY ("zone") REFERENCES "public"."zones"("chain_id") ON UPDATE restrict ON DELETE restrict, UNIQUE ("rpc_addr"));
