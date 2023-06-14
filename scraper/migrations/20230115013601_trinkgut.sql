-- Add migration script here
CREATE TABLE IF NOT EXISTS trinkgut_scrapes
(
    id           serial PRIMARY KEY,
    product_name text NOT NULL,
    price        text NOT NULL,
    description  text NOT NULL,
    image_url    text NOT NULL,
    market_id    text NOT NULL,
    created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trinkgut_markets
(
    id         serial PRIMARY KEY,
    name       text NOT NULL,
    market_id  text NOT NULL,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trinkgut_market__token
(
    id         serial PRIMARY KEY,
    market_id  text NOT NULL,
    token      text NOT NULL,
    created_at timestamptz DEFAULT now()
);

ALTER TYPE store ADD VALUE if NOT EXISTS 'trinkgut';
