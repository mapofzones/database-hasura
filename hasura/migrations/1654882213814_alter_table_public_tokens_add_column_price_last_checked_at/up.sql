ALTER TABLE "public"."tokens" ADD COLUMN "price_last_checked_at" timestamp NOT NULL DEFAULT now();
