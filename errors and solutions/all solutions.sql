-- 1. Data Privacy Compliance
-- Implementing column-level encryption for sensitive data

-- Create an extension for pgcrypto if not already created
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create a function to encrypt data
CREATE OR REPLACE FUNCTION encrypt_data(data TEXT, key TEXT) RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to decrypt data
CREATE OR REPLACE FUNCTION decrypt_data(encrypted_data BYTEA, key TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(encrypted_data, key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Example usage in a table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email BYTEA,
    phone BYTEA
);

-- Insert encrypted data
INSERT INTO customers (name, email, phone)
VALUES (
    'John Doe',
    encrypt_data('john@example.com', 'myencryptionkey'),
    encrypt_data('1234567890', 'myencryptionkey')
);

-- Query decrypted data
SELECT 
    name,
    decrypt_data(email, 'myencryptionkey') AS decrypted_email,
    decrypt_data(phone, 'myencryptionkey') AS decrypted_phone
FROM customers;

-- 2. Handling Peak Load Times
-- Implementing a simple rate limiting function

CREATE TABLE rate_limit (
    ip_address INET PRIMARY KEY,
    request_count INT DEFAULT 0,
    last_request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION check_rate_limit(client_ip INET, max_requests INT, time_window INTERVAL)
RETURNS BOOLEAN AS $$
DECLARE
    current_count INT;
BEGIN
    -- Insert or update the rate limit record
    INSERT INTO rate_limit (ip_address, request_count, last_request_time)
    VALUES (client_ip, 1, CURRENT_TIMESTAMP)
    ON CONFLICT (ip_address) DO UPDATE
    SET request_count = CASE
        WHEN rate_limit.last_request_time + time_window < CURRENT_TIMESTAMP THEN 1
        ELSE rate_limit.request_count + 1
    END,
    last_request_time = CURRENT_TIMESTAMP;

    -- Check if the rate limit has been exceeded
    SELECT request_count INTO current_count
    FROM rate_limit
    WHERE ip_address = client_ip;

    RETURN current_count <= max_requests;
END;
$$ LANGUAGE plpgsql;

-- Example usage
SELECT check_rate_limit('192.168.1.1'::INET, 100, INTERVAL '1 hour');

-- 3. Multi-tenancy Challenges
-- Implementing Row Level Security (RLS) for multi-tenancy

-- Create a tenants table
CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- Create a products table with tenant_id
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    name TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Enable RLS on the products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create a policy that only allows access to a tenant's own products
CREATE POLICY tenant_isolation_policy ON products
    USING (tenant_id = current_setting('app.current_tenant_id')::INT);

-- Function to set the current tenant
CREATE OR REPLACE FUNCTION set_current_tenant(tenant_id INT) RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', tenant_id::TEXT, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Example usage
SELECT set_current_tenant(1);
INSERT INTO products (tenant_id, name, price) VALUES (1, 'Product A', 19.99);
SELECT * FROM products;  -- This will only show products for tenant 1

-- 4. Real-time Inventory Management
-- Implementing optimistic locking for inventory updates

CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    quantity INT NOT NULL,
    version INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION update_inventory(p_product_id INT, p_quantity INT, p_version INT)
RETURNS BOOLEAN AS $$
DECLARE
    updated_rows INT;
BEGIN
    UPDATE inventory
    SET quantity = quantity - p_quantity,
        version = version + 1
    WHERE product_id = p_product_id
      AND version = p_version
      AND quantity >= p_quantity;

    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    
    RETURN updated_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- Example usage
INSERT INTO inventory (product_id, quantity) VALUES (1, 100);

-- Simulate two concurrent transactions
BEGIN;
SELECT update_inventory(1, 10, 0);  -- This should succeed
COMMIT;

BEGIN;
SELECT update_inventory(1, 5, 0);  -- This should fail due to version mismatch
COMMIT;

-- 5. Database Version Control and Schema Evolution
-- Using Flyway for database migrations (This would typically be done outside PostgreSQL)

-- Example migration script (V1__Create_customers_table.sql)
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Example migration script (V2__Add_customer_status.sql)
ALTER TABLE customers ADD COLUMN status TEXT DEFAULT 'active';

-- These scripts would be placed in a 'migrations' folder and run using Flyway CLI or API

-- 6. Cold Data Management
-- Using TimescaleDB for time-series data management

-- Create a hypertable for order data
CREATE TABLE orders (
    id SERIAL,
    customer_id INT,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL
);

-- Convert to hypertable
SELECT create_hypertable('orders', 'order_date');

-- Insert sample data
INSERT INTO orders (customer_id, order_date, total_amount)
SELECT 
    floor(random() * 1000 + 1)::int,
    timestamp '2020-01-01 00:00:00' + 
        (random() * (timestamp '2023-01-01 00:00:00' - 
                     timestamp '2020-01-01 00:00:00')),
    (random() * 1000)::decimal(10,2)
FROM generate_series(1, 1000000);

-- Query recent data (fast)
SELECT * FROM orders
WHERE order_date > now() - interval '1 month';

-- Set up retention policy
SELECT add_retention_policy('orders', INTERVAL '2 years');

-- 7. Handling Unstructured Data
-- Using JSONB for flexible schema storage

CREATE TABLE product_reviews (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    review_data JSONB NOT NULL
);

-- Insert a review
INSERT INTO product_reviews (product_id, review_data)
VALUES (1, '{"rating": 5, "title": "Great product!", "text": "I love this product.", "pros": ["durable", "easy to use"], "cons": ["expensive"]}');

-- Query JSONB data
SELECT * FROM product_reviews
WHERE review_data->>'rating' = '5';

-- Create a GIN index for faster JSONB queries
CREATE INDEX idx_review_data ON product_reviews USING GIN (review_data);

-- Full-text search on JSONB data
CREATE INDEX idx_review_text ON product_reviews USING GIN ((to_tsvector('english', review_data->>'text')));

SELECT * FROM product_reviews
WHERE to_tsvector('english', review_data->>'text') @@ to_tsquery('english', 'love & product');

-- 8. Maintaining Data Quality
-- Implementing CHECK constraints and triggers

ALTER TABLE customers
ADD CONSTRAINT check_email_format
CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

CREATE OR REPLACE FUNCTION validate_phone_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.phone !~ '^\+?[1-9]\d{1,14}$' THEN
        RAISE EXCEPTION 'Invalid phone number format';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_phone_number
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION validate_phone_number();

-- 9. Managing Database Dependencies
-- This is typically handled through proper database design and documentation
-- Here's an example of using schema namespaces to organize objects

CREATE SCHEMA inventory;
CREATE SCHEMA sales;

CREATE TABLE inventory.products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    stock INT NOT NULL
);

CREATE TABLE sales.orders (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sales.order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES sales.orders(id),
    product_id INT REFERENCES inventory.products(id),
    quantity INT NOT NULL
);

-- 10. Handling International Transactions
-- Implementing multi-currency support

CREATE TABLE currencies (
    code CHAR(3) PRIMARY KEY,
    name TEXT NOT NULL,
    symbol TEXT NOT NULL
);

CREATE TABLE exchange_rates (
    from_currency CHAR(3) REFERENCES currencies(code),
    to_currency CHAR(3) REFERENCES currencies(code),
    rate DECIMAL(20, 10) NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_currency, to_currency)
);

CREATE OR REPLACE FUNCTION convert_currency(
    amount DECIMAL(20, 2),
    from_currency CHAR(3),
    to_currency CHAR(3)
) RETURNS DECIMAL(20, 2) AS $$
DECLARE
    exchange_rate DECIMAL(20, 10);
BEGIN
    SELECT rate INTO exchange_rate
    FROM exchange_rates
    WHERE exchange_rates.from_currency = convert_currency.from_currency
    AND exchange_rates.to_currency = convert_currency.to_currency;

    IF exchange_rate IS NULL THEN
        RAISE EXCEPTION 'Exchange rate not found for % to %', from_currency, to_currency;
    END IF;

    RETURN amount * exchange_rate;
END;
$$ LANGUAGE plpgsql;

-- Example usage
INSERT INTO currencies VALUES ('USD', 'US Dollar', '$'), ('EUR', 'Euro', '€');
INSERT INTO exchange_rates VALUES ('USD', 'EUR', 0.82);

SELECT convert_currency(100.00, 'USD', 'EUR');