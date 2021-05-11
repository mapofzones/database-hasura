alter table "public"."zone_nodes" drop constraint "zone_nodes_pkey";
alter table "public"."zone_nodes"
    add constraint "zone_nodes_pkey" 
    primary key ( "zone", "rpc_addr" );
