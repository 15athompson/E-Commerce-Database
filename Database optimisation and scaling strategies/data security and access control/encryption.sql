-- Example using pgcrypto extension
CREATE EXTENSION pgcrypto;

ALTER TABLE customers
ADD COLUMN encrypted_credit_card bytea;

-- Encrypt credit card data
UPDATE customers
SET encrypted_credit_card = pgp_sym_encrypt(credit_card, 'secret_key');