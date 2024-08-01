-- Enable TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Convert orders table to a hypertable
SELECT create_hypertable('orders', 'order_date');

-- Create a continuous aggregate for real-time analytics
CREATE MATERIALIZED VIEW hourly_sales
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', order_date) AS hour,
       sum(total_amount) AS total_sales
FROM orders
GROUP BY 1;

-- Set up a policy for automatic data retention
SELECT add_retention_policy('orders', INTERVAL '1 year');

-- Compress chunks older than 1 month
SELECT add_compression_policy('orders', INTERVAL '1 month');

-- Query example
SELECT hour, total_sales
FROM hourly_sales
WHERE hour >= NOW() - INTERVAL '24 hours'
ORDER BY hour DESC;