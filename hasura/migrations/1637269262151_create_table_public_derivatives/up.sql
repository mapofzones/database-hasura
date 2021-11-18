CREATE TABLE "public"."derivatives"("zone" varchar NOT NULL, "full_denom" varchar NOT NULL, "base_denom" varchar, "origin_zone" varchar, PRIMARY KEY ("zone","full_denom") , FOREIGN KEY ("zone") REFERENCES "public"."zones"("chain_id") ON UPDATE restrict ON DELETE restrict, FOREIGN KEY ("base_denom", "origin_zone") REFERENCES "public"."tokens"("base_denom", "zone") ON UPDATE restrict ON DELETE restrict);
