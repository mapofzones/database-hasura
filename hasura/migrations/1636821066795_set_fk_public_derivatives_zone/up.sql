alter table "public"."derivatives"
           add constraint "derivatives_zone_fkey"
           foreign key ("zone")
           references "public"."zones"
           ("chain_id") on update restrict on delete restrict;
