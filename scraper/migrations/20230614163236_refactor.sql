-- Add migration script here
alter table markets
    rename to rewe_markets;

alter table token__market
    rename to rewe_token__market;

alter table trinkgut_market__token
    rename to trinkgut_token__market;

