CREATE TABLE product_bundles (
  bundle_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2)
);

CREATE TABLE bundle_items (
  bundle_id INTEGER REFERENCES product_bundles(bundle_id),
  product_id INTEGER REFERENCES products(product_id),
  quantity INTEGER DEFAULT 1,
  PRIMARY KEY (bundle_id, product_id)
);