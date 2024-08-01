CREATE OR REPLACE FUNCTION publish_to_kafka() RETURNS TRIGGER AS $$
DECLARE
    kafka_message JSON;
BEGIN
    kafka_message = row_to_json(NEW);
    
    -- Use a Kafka client library to publish the message
    -- This is a placeholder for the actual Kafka publishing code
    PERFORM pg_notify('kafka_channel', kafka_message::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_kafka_trigger
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION publish_to_kafka();