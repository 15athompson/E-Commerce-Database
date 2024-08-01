-- Create roles and grant appropriate permissions
CREATE ROLE readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Use parameterized queries in application code
const query = 'SELECT * FROM products WHERE product_id = $1';
const values = [productId];
await client.query(query, values);