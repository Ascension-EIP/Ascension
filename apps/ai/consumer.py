import pika
import json
import os


def on_message(ch, method, properties, body):
    """Callback appelé pour chaque message reçu."""
    job = json.loads(body)
    print(f"Received job: {job['job_id']}")
    try:
        # ... télécharger vidéo, analyser, sauvegarder résultats ...
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        print(f"Error: {e}")
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


def main():
    """Point d'entrée du worker RabbitMQ."""
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=os.getenv('RABBITMQ_HOST', 'localhost'),
            port=int(os.getenv('RABBITMQ_PORT', '5672')),
            credentials=pika.PlainCredentials(
                os.getenv('RABBITMQ_DEFAULT_USER', 'guest'),
                os.getenv('RABBITMQ_DEFAULT_PASS', 'guest'),
            ),
        )
    )
    channel = connection.channel()

    # Déclare la queue (durable = survit au restart de RabbitMQ)
    channel.queue_declare(queue='vision.skeleton', durable=True)

    # Un seul job à la fois par worker
    channel.basic_qos(prefetch_count=1)

    # S'abonner à la queue
    channel.basic_consume(
        queue='vision.skeleton',
        on_message_callback=on_message,
        auto_ack=False,
    )

    print('Worker waiting for jobs...')
    channel.start_consuming()


if __name__ == '__main__':
    print("Starting AI worker...")
    main()
