-- Add migration script here
create type store as enum ('rewe', 'aldinord');

alter type store owner to monster_discount;

create table if not exists markets
(
    id         integer                                not null
        constraint markets_pk
            primary key,
    created_at timestamp with time zone default now() not null,
    store      store                    default 'rewe'::store
);

alter table markets
    owner to monster_discount;

create table if not exists scrapes
(
    id         serial
        constraint scrapes_pk
            primary key,
    discounted boolean                                                    not null,
    created_at timestamp with time zone default now()                     not null,
    success    boolean                  default true                      not null,
    price      integer,
    store_info text                                                       ,
    store      varchar(32)              default 'rewe'::character varying not null
);

alter table scrapes
    owner to monster_discount;

create table if not exists token__market
(
    token      varchar(300) not null,
    market_id  integer      not null
        constraint user__market_markets_id_fk
            references markets,
    wants_aldi boolean default false
);

alter table token__market
    owner to monster_discount;

