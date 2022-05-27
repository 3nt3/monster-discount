-- this was all generated by datagrip, no idea why it's so obfuscated
create table if not exists markets
(
    id         integer                                not null
        constraint markets_pk
            primary key,
    created_at timestamp with time zone default now() not null
);

alter table markets
    owner to monster_discount;


create table if not exists scrapes
(
    id         serial
        constraint scrapes_pk
            primary key,
    discounted boolean                                not null,
    created_at timestamp with time zone default now() not null,
    success    boolean                  default true  not null
);

alter table scrapes
    owner to monster_discount;


create table if not exists token__market
(
    token     varchar(300) not null,
    market_id integer
        constraint user__market_markets_id_fk
            references markets not null
);

alter table token__market
    owner to monster_discount;


