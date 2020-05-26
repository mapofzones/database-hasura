ALTER TABLE "public"."blocks_log" ADD COLUMN "last_updated_at" timestamp NOT NULL DEFAULT now();
