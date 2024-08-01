-- Create a materialized view for real-time sales analytics
CREATE MATERIALIZED VIEW real_time_sales AS
SELECT
    DATE_TRUNC('hour', o.order_date) AS hour,
    p.category,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY DATE_TRUNC('hour', o.order_date), p.category;

-- Create a function to refresh the materialized view
CREATE OR REPLACE FUNCTION refresh_real_time_sales() RETURNS trigger AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY real_time_sales;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to refresh the view on new orders
CREATE TRIGGER refresh_real_time_sales_trigger
AFTER INSERT ON orders
FOR EACH STATEMENT EXECUTE FUNCTION refresh_real_time_sales();