-- Enable pgcrypto extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create a function to encrypt sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data() RETURNS trigger AS $$
BEGIN
    NEW.credit_card = pgp_sym_encrypt(NEW.credit_card, current_setting('app.encryption_key'));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encrypt_customer_data
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION encrypt_sensitive_data();

-- Set the encryption key (in a secure manner, not directly in the code)
ALTER DATABASE your_database SET app.encryption_key TO 'your_secure_key';