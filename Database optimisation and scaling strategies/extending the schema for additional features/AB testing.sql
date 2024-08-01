CREATE TABLE ab_tests (
  test_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  start_date DATE,
  end_date DATE
);

CREATE TABLE ab_test_variants (
  variant_id SERIAL PRIMARY KEY,
  test_id INTEGER REFERENCES ab_tests(test_id),
  name VARCHAR(50) NOT NULL
);

CREATE TABLE ab_test_results (
  result_id SERIAL PRIMARY KEY,
  variant_id INTEGER REFERENCES ab_test_variants(variant_id),
  customer_id INTEGER REFERENCES customers(customer_id),
  conversion BOOLEAN,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);