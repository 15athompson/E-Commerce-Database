import pika

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()

channel.queue_declare(queue='order_processing')

def callback(ch, method, properties, body):
    print(f" [x] Received {body}")
    # Process the order
    # If processing fails, requeue the message
    # ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

channel.basic_consume(queue='order_processing', on_message_callback=callback, auto_ack=True)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()