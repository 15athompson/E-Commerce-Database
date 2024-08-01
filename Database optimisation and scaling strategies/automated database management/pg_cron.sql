-- Automated VACUUM
SELECT cron.schedule('nightly-vacuum', '0 0 * * *', 'VACUUM ANALYZE');

-- Automated backup
SELECT cron.schedule('daily-backup', '0 1 * * *', $$
    SELECT pg_dump_cmd('dbname=ecommerce') AS backup_status;
$$);

-- Automated index maintenance
CREATE OR REPLACE FUNCTION maintain_indexes() RETURNS void AS $$
BEGIN
    EXECUTE 'REINDEX DATABASE ecommerce';
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule('weekly-reindex', '0 0 * * 0', 'SELECT maintain_indexes()');