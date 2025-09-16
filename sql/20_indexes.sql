-- 20_indexes.sql
-- Performance indexes

CREATE INDEX idx_orders_user_date   ON orders(user_id, order_date);
CREATE INDEX idx_order_items_order  ON order_items(order_id);
CREATE INDEX idx_order_items_prod   ON order_items(product_id);
CREATE INDEX idx_payments_order     ON payments(order_id);
CREATE INDEX idx_events_user_time   ON events(user_id, event_time);
CREATE INDEX idx_users_created      ON users(created_at);
CREATE INDEX idx_orders_date        ON orders(order_date);
