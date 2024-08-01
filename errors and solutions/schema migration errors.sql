-- V1__Create_products_table.sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- V2__Add_description_to_products.sql
ALTER TABLE products ADD COLUMN description TEXT;