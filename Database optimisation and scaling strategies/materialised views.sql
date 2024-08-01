CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT DATE_TRUNC('day', order_date) AS date, SUM(total_amount) AS daily_total
FROM orders
GROUP BY DATE_TRUNC('day', order_date);

-- Refresh the view
REFRESH MATERIALIZED VIEW mv_daily_sales;