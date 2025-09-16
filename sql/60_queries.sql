-- 60_queries.sql
-- Copy/paste runnable analysis queries

-- 6.1 Top products (90 days)
WITH recent AS (
  SELECT * FROM orders WHERE order_date >= now() - interval '90 days' AND status IN ('paid','shipped')
)
SELECT p.product_name,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM recent r
JOIN order_items oi ON oi.order_id = r.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- 6.2 Monthly KPIs
SELECT * FROM mv_monthly_kpis ORDER BY month;

-- 6.3 CLV (gross margin)
SELECT u.user_id, u.email,
       SUM( (oi.unit_price - p.cost) * oi.quantity ) AS gross_margin_ltv
FROM users u
JOIN orders o ON o.user_id = u.user_id AND o.status IN ('paid','shipped')
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY u.user_id, u.email
ORDER BY gross_margin_ltv DESC;

-- 6.4 Cohort retention
WITH cohorts AS (
  SELECT user_id, date_trunc('month', created_at) AS signup_month FROM users
),
activity AS (
  SELECT user_id, date_trunc('month', order_date) AS active_month
  FROM orders WHERE status IN ('paid','shipped')
),
cohort_matrix AS (
  SELECT c.signup_month::date AS signup_month,
         a.active_month::date AS active_month,
         COUNT(DISTINCT a.user_id) AS active_users
  FROM cohorts c
  JOIN activity a USING (user_id)
  GROUP BY 1,2
)
SELECT signup_month,
       active_month,
       EXTRACT(MONTH FROM age(active_month, signup_month))::int AS month_offset,
       active_users
FROM cohort_matrix
ORDER BY signup_month, active_month;

-- 6.5 RFM scoring (quartiles)
WITH tx AS (
  SELECT u.user_id, u.email,
         MAX(o.order_date) AS last_order,
         COUNT(DISTINCT o.order_id) AS freq,
         SUM(oi.quantity * oi.unit_price) AS monetary
  FROM users u
  JOIN orders o ON o.user_id = u.user_id AND o.status IN ('paid','shipped')
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY u.user_id, u.email
),
scored AS (
  SELECT *,
    NTILE(4) OVER (ORDER BY (now() - last_order)) AS r_quartile,
    NTILE(4) OVER (ORDER BY freq DESC)            AS f_quartile,
    NTILE(4) OVER (ORDER BY monetary DESC)        AS m_quartile
  FROM tx
)
SELECT user_id, email, last_order::date, freq, monetary,
       r_quartile, f_quartile, m_quartile,
       (r_quartile + f_quartile + m_quartile) AS rfm_score
FROM scored
ORDER BY rfm_score DESC, monetary DESC;

-- 6.6 Funnel conversion (60 days)
WITH base AS (
  SELECT user_id,
    BOOL_OR(event_type='visit')       FILTER (WHERE event_time >= now()-interval '60 days') AS visited,
    BOOL_OR(event_type='checkout')    FILTER (WHERE event_time >= now()-interval '60 days') AS checkout,
    BOOL_OR(event_type='purchase')    FILTER (WHERE event_time >= now()-interval '60 days') AS purchased
  FROM events
  GROUP BY user_id
)
SELECT
  COUNT(*)                                         AS users_seen,
  SUM(CASE WHEN visited  THEN 1 ELSE 0 END)        AS visited,
  SUM(CASE WHEN checkout THEN 1 ELSE 0 END)        AS checkout,
  SUM(CASE WHEN purchased THEN 1 ELSE 0 END)       AS purchased,
  ROUND(100.0 * SUM(CASE WHEN checkout THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN visited THEN 1 ELSE 0 END),0), 2) AS visit_to_checkout_pct,
  ROUND(100.0 * SUM(CASE WHEN purchased THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN checkout THEN 1 ELSE 0 END),0), 2) AS checkout_to_purchase_pct
FROM base;

-- 6.7 Also-bought pairs
WITH pairs AS (
  SELECT oi1.product_id AS a, oi2.product_id AS b, COUNT(*) AS together
  FROM order_items oi1
  JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
  JOIN orders o ON o.order_id = oi1.order_id AND o.status IN ('paid','shipped')
  GROUP BY 1,2
)
SELECT p1.product_name AS product, p2.product_name AS also_bought, together
FROM pairs
JOIN products p1 ON p1.product_id = pairs.a
JOIN products p2 ON p2.product_id = pairs.b
ORDER BY together DESC, product, also_bought;
