-- Add migration script here
create table trinkgut_scrapes (
    id serial primary key,
    url text not null,
    product_name text not null,
    price text not null,
    description text not null,
    image_url text not null,
    created_at timestamptz default utcnow()
);

create table trinkgut_markets (
    id serial primary key,
    name text not null,
    market_id text not null,
    created_at timestamptz default utcnow()
);

create table trinkgut_market__token (
    id serial primary key,
    market_id text not null,
    token text not null,
    created_at timestamptz default utcnow()
);

alter type store add value if not exists 'trinkgut';
