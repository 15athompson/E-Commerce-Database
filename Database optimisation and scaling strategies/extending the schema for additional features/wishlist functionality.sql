CREATE TABLE wishlists (
  wishlist_id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(customer_id),
  name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wishlist_items (
  wishlist_id INTEGER REFERENCES wishlists(wishlist_id),
  product_id INTEGER REFERENCES products(product_id),
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id, product_id)
);