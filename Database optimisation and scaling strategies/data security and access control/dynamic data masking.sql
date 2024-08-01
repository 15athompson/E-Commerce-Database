CREATE OR REPLACE FUNCTION mask_sensitive_data() RETURNS trigger AS $$
BEGIN
    IF current_user != 'admin' THEN
        NEW.email = regexp_replace(NEW.email, '^(.*)@', '****@');
        NEW.phone = regexp_replace(NEW.phone, '(\d{3})\d{4}(\d{4})', '\1****\2');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mask_customer_data
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION mask_sensitive_data();