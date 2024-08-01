-- Create a function to preprocess data
CREATE OR REPLACE FUNCTION preprocess_data() 
RETURNS TABLE (customer_id int, features float[]) 
AS $$
    import pandas as pd
    from sklearn.preprocessing import StandardScaler
    
    # Fetch data
    data = plpy.execute("""
        SELECT c.customer_id, 
               AVG(o.total_amount) as avg_order_value,
               COUNT(o.order_id) as order_count,
               MAX(o.order_date) - MIN(o.order_date) as customer_lifetime
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id
    """)
    
    # Convert to pandas DataFrame
    df = pd.DataFrame(data)
    
    # Normalize features
    scaler = StandardScaler()
    features = scaler.fit_transform(df[['avg_order_value', 'order_count', 'customer_lifetime']])
    
    # Return preprocessed data
    return [(row['customer_id'], feature.tolist()) for row, feature in zip(data, features)]
$$ LANGUAGE plpython3u;

-- Train a k-means clustering model
CREATE OR REPLACE FUNCTION train_kmeans_model()
RETURNS void AS $$
    SELECT madlib.kmeans_train(
        'preprocess_data',
        'kmeans_model',
        3,  -- number of clusters
        'madlib.squared_dist_norm2',
        20, -- max number of iterations
        0.001 -- convergence threshold
    );
$$ LANGUAGE SQL;

-- Predict cluster for a customer
CREATE OR REPLACE FUNCTION predict_customer_cluster(p_customer_id int)
RETURNS int AS $$
    SELECT (madlib.kmeans_predict(
        array_to_string(features, ','),
        'kmeans_model'
    )).cluster_id
    FROM preprocess_data()
    WHERE customer_id = p_customer_id;
$$ LANGUAGE SQL;

-- Usage
SELECT train_kmeans_model();
SELECT predict_customer_cluster(1);