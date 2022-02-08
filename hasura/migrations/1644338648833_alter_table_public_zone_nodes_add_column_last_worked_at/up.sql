ALTER TABLE "public"."zone_nodes" ADD COLUMN "last_worked_at" timestamp NOT NULL DEFAULT now();
