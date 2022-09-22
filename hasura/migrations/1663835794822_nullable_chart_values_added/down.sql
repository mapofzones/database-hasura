
ALTER TABLE "flat"."blockchain_tf_charts" ALTER COLUMN "point_value" SET NOT NULL;

ALTER TABLE "flat"."blockchain_tf_switched_charts" ALTER COLUMN "point_value" SET NOT NULL;

ALTER TABLE "flat"."total_tf_switched_charts" ALTER COLUMN "point_value" SET NOT NULL;
