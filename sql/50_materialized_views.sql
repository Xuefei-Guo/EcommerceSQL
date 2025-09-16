-- 50_materialized_views.sql
-- Materialized views and refresh helpers

CREATE MATERIALIZED VIEW mv_monthly_kpis AS
WITH orders_clean AS (
  SELECT * FROM orders WHERE status IN ('paid','shipped')
),
order_value AS (
  SELECT o.order_id, o.user_id, date_trunc('month', o.order_date) AS month,
         SUM(oi.quantity * oi.unit_price) AS revenue
  FROM orders_clean o
  JOIN order_items oi USING (order_id)
  GROUP BY o.order_id, o.user_id, date_trunc('month', o.order_date)
),
customer_orders AS (
  SELECT user_id, month, COUNT(*) AS orders_cnt, SUM(revenue) AS revenue
  FROM order_value
  GROUP BY user_id, month
)
SELECT
  month::date                                 AS month,
  COUNT(DISTINCT ov.order_id)                  AS orders,
  COUNT(DISTINCT ov.user_id)                   AS customers,
  SUM(ov.revenue)                              AS revenue,
  AVG(ov.revenue)                              AS aov,
  SUM(ov.revenue) / NULLIF(COUNT(DISTINCT ov.user_id),0) AS rev_per_cust,
  (SUM( CASE WHEN co.orders_cnt >= 2 THEN 1 ELSE 0 END )::decimal
   / NULLIF(COUNT(DISTINCT ov.user_id),0))      AS repeat_rate
FROM order_value ov
JOIN customer_orders co USING (user_id, month)
GROUP BY month
ORDER BY month;

-- Unique index enables optional CONCURRENTLY refresh from a session
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_monthly_kpis_month ON mv_monthly_kpis (month);

-- Safe helper: non-concurrent (works inside function/transaction)
CREATE OR REPLACE FUNCTION refresh_monthly_kpis() RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_monthly_kpis;
END;$$;
