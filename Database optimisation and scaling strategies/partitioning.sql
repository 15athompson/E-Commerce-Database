CREATE TABLE orders (
  order_id SERIAL,
  customer_id INTEGER,
  order_date DATE,
  total_amount DECIMAL(10, 2)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2023 PARTITION OF orders
  FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');