alter table "public"."ibc_clients"
           add constraint "ibc_clients_chain_id_fkey"
           foreign key ("chain_id")
           references "public"."zones"
           ("chain_id") on update restrict on delete restrict;
