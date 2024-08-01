-- Create a checksum function
CREATE OR REPLACE FUNCTION table_checksum(table_name text) RETURNS bigint AS $$
DECLARE
    result bigint;
BEGIN
    EXECUTE format('SELECT sum(hashtext(t.*::text)) FROM %I t', table_name) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Use the function to verify data integrity
SELECT table_checksum('products') AS checksum_before;
-- Perform migration
SELECT table_checksum('products') AS checksum_after;