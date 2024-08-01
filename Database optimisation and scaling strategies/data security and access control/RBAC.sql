CREATE ROLE readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

CREATE ROLE order_processor;
GRANT SELECT, INSERT, UPDATE ON orders, order_items TO order_processor;