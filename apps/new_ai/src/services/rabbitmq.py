# @date 2026-09-17
# @file rabbitmq.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
import time
from typing import Self

import pika
from pika import BlockingConnection
from pika.adapters.blocking_connection import BlockingChannel

from common.models.broker import BrokerModel
from common.utils.errors import throw_if_none
from common.utils.logger import log



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
            exchange="events",
        )
        throw_if_none(self.config)
        log.info(self.config)
        return self

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        for i in range(1, self.config.max_retries + 1):
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
            except Exception as e:
                log.warning(
                    "RabbitMQ not ready (attempt %d/%d), retrying in %ds…",
                    i,
                    self.config.max_retries,
                    self.config.retry_delay,
                )
                log.error(f"Error: {e}")
                time.sleep(self.config.retry_delay)
            else:
                log.info(
                    "Connected to RabbitMQ at %s:%d",
                    self.config.host,
                    self.config.port,
                )
                return self

        raise Exception(  # noqa: TRY002
            f"Could not connect to RabbitMQ after {self.config.max_retries} attempts."
        )

    def setup_channel(self) -> Self:
        from common.utils.macro import BROKER_BINDINGS
        self.channel.basic_qos(prefetch_count=1)
        self.channel.exchange_declare(
            exchange=self.config.exchange,
            exchange_type="topic",
            durable=True,
        )
        for bind in BROKER_BINDINGS:
            self.channel.queue_declare(queue=bind.queue, durable=True)
            self.channel.queue_bind(
                queue=bind.queue, routing_key=bind.routing_key, exchange=self.config.exchange
            )
        return self

    def start_consuming(self) -> Self:
        """Start listening for jobs on the queue."""
        from common.utils.macro import BROKER_BINDINGS  # avoids a circular import with worker.handlers

        for bind in BROKER_BINDINGS:
            self.channel.basic_consume(
                queue=bind.queue,
                on_message_callback=bind.callback,
                auto_ack=False,
            )
            log.info("Consuming jobs from %s...", bind.queue)
        self.channel.start_consuming()
        return self
