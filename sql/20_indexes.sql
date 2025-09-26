-- 20_indexes.sql
-- Indexes to speed up common queries (filtering, joins, aggregations)

-- index on orders for filtering by user and date range
CREATE INDEX idx_orders_user_date   ON orders(user_id, order_date);

-- index on order_items for joining with orders
CREATE INDEX idx_order_items_order  ON order_items(order_id);

-- index on order_items for JOIN with products or SUM / GROUP BY product
CREATE INDEX idx_order_items_prod   ON order_items(product_id);

-- index on payments for joining with orders
CREATE INDEX idx_payments_order     ON payments(order_id);

-- index on events for filtering by user and time range
CREATE INDEX idx_events_user_time   ON events(user_id, event_time);

-- index on users for filtering by creation date
CREATE INDEX idx_users_created      ON users(created_at);

-- index on orders for filtering by order date
CREATE INDEX idx_orders_date        ON orders(order_date);
