-- 60_queries.sql
-- analysis queries

-- Top products (90 days)
WITH recent AS (
  -- Get recent orders in 'paid' or 'shipped' status
  SELECT * FROM orders WHERE order_date >= now() - interval '90 days' AND status IN ('paid','shipped')
)

-- Top products by revenue
SELECT p.product_name,
       SUM(oi.quantity) AS units, -- units sold per product
       SUM(oi.quantity * oi.unit_price) AS revenue, -- revenue per product
       SUM(oi.quantity * (oi.unit_price - p.cost)) AS gross_margin -- gross margin per product
FROM recent r
JOIN order_items oi ON oi.order_id = r.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Monthly KPIs
SELECT * FROM monthly_kpis ORDER BY month;

-- CLV (gross margin)
SELECT u.user_id, u.email,
       SUM( (oi.unit_price - p.cost) * oi.quantity ) AS gross_margin_ltv -- lifetime gross margin value
FROM users u
JOIN orders o ON o.user_id = u.user_id AND o.status IN ('paid','shipped') -- only completed orders
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY u.user_id, u.email
ORDER BY gross_margin_ltv DESC; -- Top customers by gross margin

-- Cohort retention
WITH cohorts AS (
  SELECT user_id, date_trunc('month', created_at) AS signup_month FROM users
),
activity AS (
  SELECT user_id, date_trunc('month', order_date) AS active_month
  FROM orders WHERE status IN ('paid','shipped') -- only completed orders
),
cohort_matrix AS (
  SELECT c.signup_month::date AS signup_month,
         a.active_month::date AS active_month,
         COUNT(DISTINCT a.user_id) AS active_users -- active users count who signed up in signup_month and were active in active_month
  FROM cohorts c
  JOIN activity a ON c.user_id = a.user_id
  WHERE a.active_month >= c.signup_month
  GROUP BY signup_month, active_month
)
SELECT signup_month,
       active_month,
       ((EXTRACT(YEAR FROM active_month)*12 + EXTRACT(MONTH FROM active_month))
       - (EXTRACT(YEAR FROM signup_month)*12 + EXTRACT(MONTH FROM signup_month)))::int AS month_offset, -- month offset including cross-year span
FROM cohort_matrix
ORDER BY signup_month, active_month;

-- RFM scoring (quartiles)
WITH tx AS (
  SELECT u.user_id, u.email,
         MAX(o.order_date) AS last_order, -- most recent order date
         COUNT(DISTINCT o.order_id) AS freq, -- order total count
         SUM(oi.quantity * oi.unit_price) AS monetary -- total revenue
  FROM users u
  JOIN orders o ON o.user_id = u.user_id AND o.status IN ('paid','shipped') -- only completed orders
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY u.user_id, u.email
),
scored AS (
  SELECT *,
    -- NTILE divides rows into a specified number of approximately equal groups
    NTILE(4) OVER (ORDER BY (now() - last_order)) AS r_quartile,
    NTILE(4) OVER (ORDER BY freq DESC)            AS f_quartile,
    NTILE(4) OVER (ORDER BY monetary DESC)        AS m_quartile
  FROM tx
)
SELECT user_id, email, last_order::date, freq, monetary,
       r_quartile, f_quartile, m_quartile,
       (r_quartile + f_quartile + m_quartile) AS rfm_score -- combined RFM score
FROM scored
ORDER BY rfm_score DESC, monetary DESC; -- Top customers by RFM score, monetary DESC

-- Funnel conversion (60 days)
WITH recent_events AS (
  SELECT *
  FROM events
  WHERE event_time >= now() - interval '60 days' -- only last 60 days
),
-- Base events for funnel analysis
base AS (
  SELECT user_id,
         BOOL_OR(event_type='visit')    AS visited,
         BOOL_OR(event_type='checkout') AS checkout,
         BOOL_OR(event_type='purchase') AS purchased
  FROM recent_events
  GROUP BY user_id
)
SELECT
  COUNT(*) AS users_in_window, -- last 60 days users
  SUM(visited::int)  AS visited, -- total visited
  SUM(checkout::int) AS checkout, -- total checkout
  SUM(purchased::int) AS purchased, -- total purchased
  ROUND(100.0 * SUM(checkout::int) / NULLIF(SUM(visited::int),0), 2)  AS visit_to_checkout_pct, -- conversion rate from visit to checkout
  ROUND(100.0 * SUM(purchased::int) / NULLIF(SUM(checkout::int),0),2) AS checkout_to_purchase_pct -- conversion rate from checkout to purchase
FROM base;

-- Also-bought pairs
WITH pairs AS (
  SELECT oi1.product_id AS a, oi2.product_id AS b, COUNT(*) AS together
  FROM order_items oi1
  JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id -- self-join to find pairs, avoid duplicates and self-pairing
  JOIN orders o ON o.order_id = oi1.order_id AND o.status IN ('paid','shipped') -- only completed orders
  GROUP BY 1,2
)
SELECT p1.product_name AS product, p2.product_name AS also_bought, together
FROM pairs
JOIN products p1 ON p1.product_id = pairs.a -- get product name
JOIN products p2 ON p2.product_id = pairs.b -- get also-bought product name
ORDER BY together DESC, product, also_bought; -- Top also-bought pairs
