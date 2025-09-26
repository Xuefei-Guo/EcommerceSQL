-- 50_materialized_views.sql
-- Materialized views and refresh helpers

/* Keep Monthly KPIs into a materialized view for fast access
(orders, customers, revenue, AOV, revenue per customer, repeat rate)
based on orders in 'paid' or 'shipped' status
(can be refreshed periodically, e.g. daily or hourly) */
CREATE MATERIALIZED VIEW monthly_kpis AS
WITH 
-- filter order with status IN ('paid','shipped')
orders_clean AS (
  SELECT * FROM orders WHERE status IN ('paid','shipped')
),

-- get order values with user_id, month, revenue
order_value AS (
  SELECT o.order_id, o.user_id, date_trunc('month', o.order_date) AS month,
         SUM(oi.quantity * oi.unit_price) AS revenue -- order revenue
  FROM orders_clean o
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY o.order_id, o.user_id, date_trunc('month', o.order_date)
),

-- get customer orders summary per month
customer_orders AS (
  SELECT user_id, month, COUNT(*) AS orders_cnt, SUM(revenue) AS revenue
  FROM order_value
  GROUP BY user_id, month
)
SELECT
  month::date                                 AS month, -- cast to date for cleaner display
  COUNT(DISTINCT ov.order_id)                  AS orders, -- order count
  COUNT(DISTINCT ov.user_id)                   AS customers, -- user count
  SUM(ov.revenue)                              AS revenue, -- total revenue
  AVG(ov.revenue)                              AS aov, -- average order revenue
  SUM(ov.revenue) / NULLIF(COUNT(DISTINCT ov.user_id),0) AS rev_per_cust, -- revenue per customer
  (COUNT( DISTINCT CASE WHEN co.orders_cnt >= 2 THEN ov.user_id END )::decimal
   / NULLIF(COUNT(DISTINCT ov.user_id),0))      AS repeat_rate -- repeat purchase rate, users with 2+ orders / all users
FROM order_value ov
JOIN customer_orders co ON ov.user_id = co.user_id AND ov.month = co.month
GROUP BY month
ORDER BY month;

-- Unique index enables optional CONCURRENTLY refresh from a session
CREATE UNIQUE INDEX IF NOT EXISTS uq_monthly_kpis_month ON monthly_kpis (month);

-- NOTE: PostgreSQL not allowed to execute 'REFRESH MATERIALIZED VIEW CONCURRENTLY' inside a function
-- If you want to refresh concurrently, run directly at top level: REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_kpis;
-- Safe helper: non-concurrent (works inside function/transaction)
CREATE OR REPLACE FUNCTION refresh_monthly_kpis() RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW monthly_kpis;
END;$$;
