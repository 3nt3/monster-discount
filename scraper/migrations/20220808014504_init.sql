-- Add migration script here
DROP TYPE IF EXISTS store;
CREATE TYPE store AS enum ('rewe', 'aldinord');

ALTER TYPE store OWNER TO monster_discount;

CREATE TABLE IF NOT EXISTS markets
(
    id         integer                                NOT NULL
        CONSTRAINT markets_pk
            PRIMARY KEY,
    created_at timestamp WITH TIME ZONE DEFAULT NOW() NOT NULL,
    store      store                    DEFAULT 'rewe'::store
);

ALTER TABLE markets
    OWNER TO monster_discount;

CREATE TABLE IF NOT EXISTS scrapes
(
    id         serial
        CONSTRAINT scrapes_pk
            PRIMARY KEY,
    discounted boolean                                                    NOT NULL,
    created_at timestamp WITH TIME ZONE DEFAULT NOW()                     NOT NULL,
    success    boolean                  DEFAULT TRUE                      NOT NULL,
    price      integer,
    store_info text,
    store      varchar(32)              DEFAULT 'rewe'::character varying NOT NULL
);

ALTER TABLE scrapes
    OWNER TO monster_discount;

CREATE TABLE IF NOT EXISTS token__market
(
    token      varchar(300) NOT NULL,
    market_id  integer
        CONSTRAINT user__market_markets_id_fk
            REFERENCES markets,
    wants_aldi boolean DEFAULT FALSE
);

ALTER TABLE token__market
    OWNER TO monster_discount;

