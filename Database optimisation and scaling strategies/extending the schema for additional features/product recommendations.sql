CREATE TABLE product_recommendations (
  recommendation_id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(product_id),
  recommended_product_id INTEGER REFERENCES products(product_id),
  strength DECIMAL(3, 2) -- Recommendation strength (0-1)
);