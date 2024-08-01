CREATE TABLE user_actions (
  action_id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(customer_id),
  action_type VARCHAR(50), -- e.g., 'view', 'add_to_cart', 'purchase'
  product_id INTEGER REFERENCES products(product_id),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);