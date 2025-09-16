-- 10_tables.sql
-- Core tables for the ecommerce analytics demo

CREATE TABLE users (
  user_id        BIGSERIAL PRIMARY KEY,
  email          CITEXT UNIQUE NOT NULL,
  full_name      TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  country        TEXT NOT NULL DEFAULT 'US'
);

CREATE TABLE categories (
  category_id    BIGSERIAL PRIMARY KEY,
  category_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
  product_id     BIGSERIAL PRIMARY KEY,
  product_name   TEXT NOT NULL,
  category_id    BIGINT NOT NULL REFERENCES categories(category_id),
  price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  cost           NUMERIC(10,2) NOT NULL CHECK (cost >= 0),
  active         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
  order_id       BIGSERIAL PRIMARY KEY,
  user_id        BIGINT NOT NULL REFERENCES users(user_id),
  order_date     TIMESTAMPTZ NOT NULL DEFAULT now(),
  status         TEXT NOT NULL CHECK (status IN ('created','paid','shipped','cancelled','refunded'))
);

CREATE TABLE order_items (
  order_item_id  BIGSERIAL PRIMARY KEY,
  order_id       BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id     BIGINT NOT NULL REFERENCES products(product_id),
  quantity       INT NOT NULL CHECK (quantity > 0),
  unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE payments (
  payment_id     BIGSERIAL PRIMARY KEY,
  order_id       BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  amount         NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  method         TEXT NOT NULL CHECK (method IN ('card','paypal','bank','giftcard')),
  paid_at        TIMESTAMPTZ NOT NULL,
  status         TEXT NOT NULL CHECK (status IN ('authorized','captured','failed','refunded'))
);

CREATE TABLE events (
  event_id       BIGSERIAL PRIMARY KEY,
  user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  event_type     TEXT NOT NULL CHECK (event_type IN ('visit','view_product','add_to_cart','checkout','purchase')),
  event_time     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE promotions (
  promo_code     TEXT PRIMARY KEY,
  description    TEXT,
  discount_pct   NUMERIC(5,2) NOT NULL CHECK (discount_pct BETWEEN 0 AND 100)
);
