CREATE OR REPLACE FUNCTION auto_shard_table(p_table_name text, p_threshold bigint) RETURNS void AS $$
DECLARE
    v_row_count bigint;
    v_shard_count int;
BEGIN
    EXECUTE 'SELECT COUNT(*) FROM ' || p_table_name INTO v_row_count;
    
    IF v_row_count > p_threshold THEN
        v_shard_count := ceil(v_row_count::float / p_threshold);
        
        FOR i IN 1..v_shard_count LOOP
            EXECUTE format('CREATE TABLE %I PARTITION OF %I FOR VALUES WITH (modulus %s, remainder %s)',
                           p_table_name || '_shard_' || i, p_table_name, v_shard_count, i - 1);
        END LOOP;
        
        EXECUTE format('ALTER TABLE %I SET UNLOGGED', p_table_name);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT auto_shard_table('orders', 1000000);