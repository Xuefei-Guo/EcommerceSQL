-- 10_tables.sql
-- Core tables for the ecommerce analytics demo

CREATE TABLE users (
  user_id        BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  email          CITEXT UNIQUE NOT NULL,
  full_name      TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(), -- time stamp with timezone
  country        TEXT NOT NULL DEFAULT 'US'
);

CREATE TABLE categories (
  category_id    BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  category_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
  product_id     BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  product_name   TEXT NOT NULL,
  category_id    BIGINT NOT NULL REFERENCES categories(category_id), -- foreign key constraint, must exist in categories
  price          NUMERIC(10,2) NOT NULL CHECK (price >= 0), -- precision = 10, scale = 2
  cost           NUMERIC(10,2) NOT NULL CHECK (cost >= 0), -- precision = 10, scale = 2
  active         BOOLEAN NOT NULL DEFAULT TRUE -- soft delete (active/inactive)
);

CREATE TABLE orders (
  order_id       BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  user_id        BIGINT NOT NULL REFERENCES users(user_id), -- foreign key constraint, must exist in users
  order_date     TIMESTAMPTZ NOT NULL DEFAULT now(), -- time stamp with timezone
  status         TEXT NOT NULL CHECK (status IN ('created','paid','shipped','cancelled','refunded')) -- check constraint
);

CREATE TABLE order_items (
  order_item_id  BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  order_id       BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE, -- foreign key constraint, must exist in orders
  product_id     BIGINT NOT NULL REFERENCES products(product_id), -- foreign key constraint, must exist in products
  quantity       INT NOT NULL CHECK (quantity > 0), -- check constraint
  unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0) -- check constraint
);

CREATE TABLE payments (
  payment_id     BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  order_id       BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE, -- foreign key constraint, must exist in orders
  amount         NUMERIC(10,2) NOT NULL CHECK (amount >= 0), -- precision = 10, scale = 2
  method         TEXT NOT NULL CHECK (method IN ('card','paypal','bank','giftcard')), -- check constraint
  paid_at        TIMESTAMPTZ NOT NULL, -- time stamp with timezone
  status         TEXT NOT NULL CHECK (status IN ('authorized','captured','failed','refunded')) -- check constraint
);

CREATE TABLE events (
  event_id       BIGSERIAL PRIMARY KEY, -- auto-incrementing ID
  user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, -- foreign key constraint, must exist in users, delete user will delete events
  event_type     TEXT NOT NULL CHECK (event_type IN ('visit','view_product','add_to_cart','checkout','purchase')), -- check constraint
  event_time     TIMESTAMPTZ NOT NULL DEFAULT now() -- time stamp with timezone
);

CREATE TABLE promotions (
  promo_code     TEXT PRIMARY KEY, -- unique promotion code
  description    TEXT, -- description of the promotion
  discount_pct   NUMERIC(5,2) NOT NULL CHECK (discount_pct BETWEEN 0 AND 100) -- precision = 5, scale = 2, check constraint
);
