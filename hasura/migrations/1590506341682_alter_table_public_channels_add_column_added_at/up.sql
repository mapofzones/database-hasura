ALTER TABLE "public"."channels" ADD COLUMN "added_at" timestamp NOT NULL DEFAULT now();
