CREATE TABLE customer_segments (
  segment_id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  description TEXT
);

ALTER TABLE customers
ADD COLUMN segment_id INTEGER REFERENCES customer_segments(segment_id);