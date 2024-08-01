-- Prepare the data
CREATE TABLE user_item_ratings AS
SELECT customer_id, product_id, COALESCE(rating, 3) as rating
FROM order_items oi
LEFT JOIN reviews r ON oi.order_id = r.order_id AND oi.product_id = r.product_id;

-- Train the model
SELECT madlib.als_train(
    'user_item_ratings',   -- source table
    'als_model',           -- output model table
    'customer_id',         -- column for user
    'product_id',          -- column for item
    'rating'               -- column for rating
);

-- Generate recommendations
CREATE OR REPLACE FUNCTION get_product_recommendations(p_customer_id integer)
RETURNS TABLE (product_id integer, score float8) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM madlib.als_recommend(
        'als_model',
        p_customer_id::text,
        10  -- number of recommendations
    ) AS (product_id integer, score float8);
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM get_product_recommendations(1);