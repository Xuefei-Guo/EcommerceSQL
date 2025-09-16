-- 40_views.sql
-- Derived views

-- 5.1 Order totals
CREATE OR REPLACE VIEW v_order_totals AS
SELECT
  o.order_id,
  o.user_id,
  o.order_date,
  o.status,
  SUM(oi.quantity * oi.unit_price) AS items_subtotal
FROM orders o
JOIN order_items oi USING (order_id)
GROUP BY o.order_id;

-- 5.2 Product performance
CREATE OR REPLACE VIEW v_product_perf AS
SELECT
  p.product_id,
  p.product_name,
  c.category_name,
  SUM(oi.quantity)                          AS units_sold,
  SUM(oi.quantity * oi.unit_price)          AS gross_revenue,
  SUM(oi.quantity * (oi.unit_price - p.cost)) AS gross_margin
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status IN ('paid','shipped')
GROUP BY p.product_id, p.product_name, c.category_name;
