-- Set appropriate isolation level
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Use advisory locks for inventory updates
SELECT pg_advisory_xact_lock(product_id) FROM products WHERE product_id = 1;

-- Implement optimistic locking
UPDATE products
SET stock_quantity = stock_quantity - 1, version = version + 1
WHERE product_id = 1 AND version = (SELECT version FROM products WHERE product_id = 1);