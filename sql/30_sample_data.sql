-- 30_sample_data.sql

-- Users
INSERT INTO users (email, full_name, created_at, country) VALUES
  ('alice@example.com','Alice Smith', now() - interval '120 days', 'US'),
  ('bob@example.com','Bob Lee',       now() - interval '90 days',  'US'),
  ('cindy@example.com','Cindy Zhao',  now() - interval '60 days',  'CA'),
  ('diego@example.com','Diego Pérez', now() - interval '45 days',  'MX'),
  ('eva@example.com','Eva Müller',    now() - interval '20 days',  'DE');

-- Categories
INSERT INTO categories (category_name) VALUES
  ('Electronics'), ('Home'), ('Books'), ('Toys');

-- Products
INSERT INTO products (product_name, category_id, price, cost, active) VALUES
  ('Wireless Headphones', 1, 129.99, 65.00, TRUE),
  ('USB-C Cable',         1,  12.99,  2.00, TRUE),
  ('Smart Lamp',          2,  49.99, 20.00, TRUE),
  ('Espresso Machine',    2, 299.00,180.00, TRUE),
  ('Novel: Data Tales',   3,  18.00,  3.00, TRUE),
  ('STEM Robot Kit',      4,  89.00, 40.00, TRUE);

-- Orders
INSERT INTO orders (user_id, order_date, status) VALUES
  (1, now() - interval '80 days',  'paid'),
  (1, now() - interval '72 days',  'shipped'),
  (2, now() - interval '50 days',  'paid'),
  (2, now() - interval '49 days',  'cancelled'),
  (3, now() - interval '30 days',  'paid'),
  (3, now() - interval '20 days',  'paid'),
  (4, now() - interval '18 days',  'refunded'),
  (5, now() - interval '10 days',  'paid');

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 2,  2, 12.99),
  (1, 5,  1, 18.00),
  (2, 1,  1,129.99),
  (2, 3,  1, 49.99),
  (3, 4,  1,299.00),
  (4, 6,  1, 89.00),
  (5, 1,  1,129.99),
  (5, 2,  3, 12.49),
  (6, 6,  2, 85.00),
  (7, 1,  1,129.99),
  (8, 3,  2, 49.99);

-- Payments
INSERT INTO payments (order_id, amount, method, paid_at, status) VALUES
  (1,  44.98, 'card',    now() - interval '80 days', 'captured'),
  (2, 179.98, 'paypal',  now() - interval '72 days', 'captured'),
  (3, 299.00, 'card',    now() - interval '50 days', 'captured'),
  (4,  89.00, 'card',    now() - interval '49 days', 'failed'),
  (5, 167.46, 'bank',    now() - interval '30 days', 'captured'),
  (6, 170.00, 'card',    now() - interval '20 days', 'captured'),
  (7, 129.99, 'card',    now() - interval '18 days', 'refunded'),
  (8, 149.97, 'giftcard',now() - interval '10 days', 'captured');

-- Events
INSERT INTO events (user_id, event_type, event_time) VALUES
  (1,'visit', now() - interval '121 days'),
  (1,'purchase', now() - interval '80 days'),
  (1,'purchase', now() - interval '72 days'),
  (2,'visit', now() - interval '91 days'),
  (2,'checkout', now() - interval '50 days'),
  (3,'visit', now() - interval '70 days'),
  (3,'view_product', now() - interval '35 days'),
  (3,'purchase', now() - interval '30 days'),
  (3,'purchase', now() - interval '20 days'),
  (4,'visit', now() - interval '40 days'),
  (4,'purchase', now() - interval '18 days'),
  (5,'visit', now() - interval '19 days'),
  (5,'purchase', now() - interval '10 days');
