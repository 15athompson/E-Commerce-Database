CREATE OR REPLACE FUNCTION suggest_indexes() RETURNS TABLE (
    table_name text,
    column_names text[],
    index_type text
) AS $$
BEGIN
    RETURN QUERY
    WITH slow_queries AS (
        SELECT schemaname, query, calls, total_time, rows
        FROM pg_stat_statements
        WHERE total_time / calls > 100  -- ms
    ),
    table_columns AS (
        SELECT table_name, array_agg(column_name::text) AS columns
        FROM information_schema.columns
        WHERE table_schema = 'public'
        GROUP BY table_name
    )
    SELECT DISTINCT ON (tc.table_name, suggested_columns)
        tc.table_name,
        suggested_columns,
        CASE
            WHEN array_length(suggested_columns, 1) > 3 THEN 'GIN'
            ELSE 'BTREE'
        END AS index_type
    FROM slow_queries sq
    CROSS JOIN LATERAL (
        SELECT array_agg(DISTINCT col) AS suggested_columns
        FROM regexp_matches(sq.query, 'WHERE\s+(\w+)', 'g') m(col)
    ) cols
    JOIN table_columns tc ON tc.columns @> cols.suggested_columns
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_indexes pi
        WHERE pi.tablename = tc.table_name
          AND pi.indexdef ~* ALL(SELECT unnest(cols.suggested_columns))
    );
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM suggest_indexes();