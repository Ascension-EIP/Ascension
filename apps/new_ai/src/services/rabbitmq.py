# @date 2026-09-10
# @file rabbitmq.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
from datetime import time
from typing import Self

import pika
from pika import BlockingConnection
from pika.adapters.blocking_connection import BlockingChannel

from common.models.broker import BrokerModel
from common.utils.errors import throw_if_none
from common.utils.logger import log


def callback(ch, method, properties, body):
    log.info(f" [x] Received {body}")


class Broker:
    def __init__(self):
        self.config: BrokerModel | None = None
        self.connection: BlockingConnection | None = None
        self.channel: BlockingChannel | None = None

    def setup_config(self) -> Self:
        broker_user = (
            os.getenv("RABBITMQ_DEFAULT_USER")
            or os.getenv("RABBITMQ_USER")
            or "ascension"
        )
        broker_pass = (
            os.getenv("RABBITMQ_DEFAULT_PASS")
            or os.getenv("RABBITMQ_PASS")
            or "ascension"
        )
        self.config = BrokerModel(
            host=os.getenv("RABBITMQ_HOST", "localhost"),
            port=int(os.getenv("RABBITMQ_PORT", "5672")),
            user=broker_user,
            password=broker_pass,
            retry_delay=int(os.getenv("RABBITMQ_RETRY_DELAY", "5")),
            max_retries=int(os.getenv("RABBITMQ_MAX_RETRIES", "12")),
            queue="ascension.skeleton",
            exchange="ascension.events",
        )
        throw_if_none(self.config)

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        for attempt in self.config.max_retries:
            try:
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=self.config.host,
                        port=self.config.port,
                        credentials=pika.PlainCredentials(
                            self.config.user, self.config.password
                        ),
                        heartbeat=60,
                        blocked_connection_timeout=300,
                    )
                )
                self.channel = self.connection.channel()
            except pika.exceptions.AMQPConnectionError:
                log.warning(
                    "RabbitMQ not ready (attempt %d/%d), retrying in %ds…",
                    attempt,
                    self.settings.max_retries,
                    self.settings.retry_delay,
                )
                time.sleep(self.settings.retry_delay)
        raise Exception(  # noqa: TRY002
            f"Could not connect to RabbitMQ after {self.settings.max_retries} attempts."
        )

    def setup_channel(self) -> Self:
        self.channel.queue_declare(queue=self.config.queue, durable=True)
        self.channel.exchange_declare(
            exchange=self.config.queue,
            exchange_type="topic",
            durable=True,
        )
        return self

        def start_consuming(self) -> Self:
            """Start listening for jobs on the queue."""
            self.channel.basic_consume(
                queue=self.config.queue,
                on_message_callback=callback,
                auto_ack=False,
            )
            log.info("Consuming jobs from %s...", self.settings.queue_skeleton)
            self.channel.start_consuming()
