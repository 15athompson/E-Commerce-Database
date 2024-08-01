-- On Shard 1
CREATE TABLE orders_shard_1 (
  CHECK ( customer_id % 2 = 0 )
) INHERITS (orders);

-- On Shard 2
CREATE TABLE orders_shard_2 (
  CHECK ( customer_id % 2 = 1 )
) INHERITS (orders);