-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM orders WHERE order_date > '2023-01-01';

-- Create index to improve performance
CREATE INDEX idx_orders_date ON orders (order_date);

-- Implement table partitioning
CREATE TABLE orders (
    order_id SERIAL,
    order_date DATE,
    -- other columns
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');