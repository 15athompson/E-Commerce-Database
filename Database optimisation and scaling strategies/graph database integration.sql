-- Create a graph
SELECT create_graph('ecommerce_graph');

-- Create vertex labels
CREATE VLABEL customer;
CREATE VLABEL product;

-- Create edge labels
CREATE ELABEL purchased;
CREATE ELABEL recommends;

-- Insert vertices
INSERT INTO customer VALUES ('customer1', '{"name": "John Doe"}');
INSERT INTO product VALUES ('product1', '{"name": "Smartphone"}');

-- Insert edges
INSERT INTO purchased VALUES ('customer1', 'product1', '{"date": "2023-06-29"}');

-- Query example: Find customers who purchased products similar to a given product
SELECT c.properties->>'name' AS customer_name
FROM product p, 
     LATERAL (SELECT * FROM recommends WHERE start_vid = p.vid) r,
     LATERAL (SELECT * FROM purchased WHERE end_vid = r.end_vid) pu,
     customer c
WHERE p.properties->>'name' = 'Smartphone'
  AND c.vid = pu.start_vid;