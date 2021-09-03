alter table "public"."headers" drop constraint "headers_pkey";
alter table "public"."headers"
    add constraint "headers_pkey" 
    primary key ( "timeframe", "is_mainnet_only" );
