-- Database Schema

-- Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending'
);

-- Order_items table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);

-- Reviews table
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    customer_id INTEGER REFERENCES customers(customer_id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inventory table
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    warehouse_id INTEGER,
    quantity INTEGER NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data insertion
INSERT INTO customers (first_name, last_name, email, phone, address)
VALUES 
    ('John', 'Doe', 'john.doe@example.com', '123-456-7890', '123 Main St, City, Country'),
    ('Jane', 'Smith', 'jane.smith@example.com', '987-654-3210', '456 Elm St, Town, Country');

INSERT INTO products (name, description, price, stock_quantity, category)
VALUES 
    ('Smartphone', 'High-end smartphone with advanced features', 999.99, 100, 'Electronics'),
    ('Laptop', 'Powerful laptop for professional use', 1499.99, 50, 'Electronics'),
    ('T-shirt', 'Comfortable cotton t-shirt', 19.99, 200, 'Clothing');

-- Advanced Queries

-- 1. Complex JOIN with subquery and window function
-- This query retrieves the top 5 customers by total order amount, along with their most recent order details
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    total_spent,
    most_recent_order_id,
    most_recent_order_date,
    most_recent_order_status
FROM customers c
JOIN (
    SELECT 
        customer_id,
        SUM(total_amount) as total_spent,
        MAX(order_id) as most_recent_order_id,
        MAX(order_date) as most_recent_order_date,
        FIRST_VALUE(status) OVER (PARTITION BY customer_id ORDER BY order_date DESC) as most_recent_order_status,
        ROW_NUMBER() OVER (ORDER BY SUM(total_amount) DESC) as rank
    FROM orders
    GROUP BY customer_id
) o ON c.customer_id = o.customer_id
WHERE o.rank <= 5
ORDER BY total_spent DESC;

-- 2. Recursive CTE to calculate product categories hierarchy
WITH RECURSIVE category_tree AS (
    SELECT product_id, name, category, 0 AS level
    FROM products
    WHERE category IS NULL
    
    UNION ALL
    
    SELECT p.product_id, p.name, p.category, ct.level + 1
    FROM products p
    JOIN category_tree ct ON p.category = ct.name
)
SELECT * FROM category_tree
ORDER BY level, name;

-- 3. Pivot table using CASE statements
-- This query creates a pivot table showing product sales by category for each month
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(CASE WHEN p.category = 'Electronics' THEN oi.quantity * oi.unit_price ELSE 0 END) AS electronics_sales,
    SUM(CASE WHEN p.category = 'Clothing' THEN oi.quantity * oi.unit_price ELSE 0 END) AS clothing_sales,
    SUM(CASE WHEN p.category NOT IN ('Electronics', 'Clothing') THEN oi.quantity * oi.unit_price ELSE 0 END) AS other_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;

-- 4. Window functions for inventory analysis
-- This query calculates the running total of inventory and percent of total inventory for each product
SELECT 
    p.product_id,
    p.name,
    i.quantity,
    SUM(i.quantity) OVER (ORDER BY p.product_id) AS running_total_inventory,
    i.quantity * 100.0 / SUM(i.quantity) OVER () AS percent_of_total_inventory
FROM products p
JOIN inventory i ON p.product_id = i.product_id
ORDER BY p.product_id;

-- 5. Full-text search using ts_vector and ts_query
-- Assuming we've added a full-text search column to the products table
ALTER TABLE products ADD COLUMN search_vector tsvector;
UPDATE products SET search_vector = to_tsvector('english', name || ' ' || COALESCE(description, ''));

CREATE INDEX products_search_idx ON products USING GIN (search_vector);

-- Now we can perform full-text search queries like this:
SELECT name, description
FROM products
WHERE search_vector @@ to_tsquery('english', 'smartphone & advanced')
ORDER BY ts_rank(search_vector, to_tsquery('english', 'smartphone & advanced')) DESC;

-- 6. Materialized view for caching complex query results
CREATE MATERIALIZED VIEW product_sales_summary AS
SELECT 
    p.product_id,
    p.name,
    p.category,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.name, p.category;

-- Refresh the materialized view
REFRESH MATERIALIZED VIEW product_sales_summary;

-- 7. Stored procedure for processing new orders
CREATE OR REPLACE PROCEDURE process_order(
    IN p_customer_id INTEGER,
    IN p_products INTEGER[],
    IN p_quantities INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INTEGER;
    v_total_amount DECIMAL(10, 2) := 0;
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_unit_price DECIMAL(10, 2);
    v_i INTEGER;
BEGIN
    -- Start transaction
    BEGIN
        -- Create new order
        INSERT INTO orders (customer_id, total_amount)
        VALUES (p_customer_id, 0)
        RETURNING order_id INTO v_order_id;

        -- Process each product
        FOR v_i IN 1..array_length(p_products, 1) LOOP
            v_product_id := p_products[v_i];
            v_quantity := p_quantities[v_i];

            -- Get product price and check stock
            SELECT price, stock_quantity INTO v_unit_price, v_quantity
            FROM products
            WHERE product_id = v_product_id
            FOR UPDATE;

            IF v_quantity < p_quantities[v_i] THEN
                RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
            END IF;

            -- Update stock
            UPDATE products
            SET stock_quantity = stock_quantity - p_quantities[v_i]
            WHERE product_id = v_product_id;

            -- Add order item
            INSERT INTO order_items (order_id, product_id, quantity, unit_price)
            VALUES (v_order_id, v_product_id, p_quantities[v_i], v_unit_price);

            -- Update total amount
            v_total_amount := v_total_amount + (p_quantities[v_i] * v_unit_price);
        END LOOP;

        -- Update order total
        UPDATE orders
        SET total_amount = v_total_amount
        WHERE order_id = v_order_id;

        -- Commit transaction
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction on error
            ROLLBACK;
            RAISE    END;
END;
$$;

-- 8. Trigger for updating inventory after order placement
CREATE OR REPLACE FUNCTION update_inventory_after_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory
    SET quantity = quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory_after_order();

-- 9. User-defined function for calculating customer lifetime value
CREATE OR REPLACE FUNCTION calculate_customer_lifetime_value(p_customer_id INTEGER)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_total_value DECIMAL(10, 2);
    v_first_order_date DATE;
    v_days_since_first_order INTEGER;
BEGIN
    SELECT 
        COALESCE(SUM(total_amount), 0),
        MIN(order_date)::DATE
    INTO v_total_value, v_first_order_date
    FROM orders
    WHERE customer_id = p_customer_id;

    v_days_since_first_order := CURRENT_DATE - v_first_order_date;

    IF v_days_since_first_order > 0 THEN
        RETURN (v_total_value / v_days_since_first_order) * 365;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Usage example:
-- SELECT calculate_customer_lifetime_value(1) AS customer_ltv;

-- 10. Complex query with multiple CTEs, window functions, and advanced aggregations
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', o.order_date), p.category
),
category_ranks AS (
    SELECT 
        month,
        category,
        sales,
        RANK() OVER (PARTITION BY month ORDER BY sales DESC) AS category_rank
    FROM monthly_sales
),
top_categories AS (
    SELECT 
        month,
        STRING_AGG(category, ', ' ORDER BY sales DESC) AS top_3_categories
    FROM category_ranks
    WHERE category_rank <= 3
    GROUP BY month
)
SELECT 
    ms.month,
    ms.category,
    ms.sales,
    ms.sales - LAG(ms.sales) OVER (PARTITION BY ms.category ORDER BY ms.month) AS sales_growth,
    ms.sales * 100.0 / SUM(ms.sales) OVER (PARTITION BY ms.month) AS percent_of_monthly_sales,
    tc.top_3_categories
FROM monthly_sales ms
JOIN top_categories tc ON ms.month = tc.month
ORDER BY ms.month DESC, ms.sales DESC;