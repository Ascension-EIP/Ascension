# @date 2026-09-07
# @file messaging.py
# @brief RabbitMQ messaging adapter for job consumption and event publication.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""RabbitMQ messaging adapter."""

import json
import logging
import time
from collections.abc import Callable
from typing import Any

import pika
from pika.adapters.blocking_connection import BlockingChannel, BlockingConnection

from src.config.settings import BrokerSettings
from src.core.exceptions import BrokerError

logger = logging.getLogger("ai-worker.messaging")


class RabbitMQClient:
    """Manages connection, subscription, and event publication with RabbitMQ."""

    def __init__(self, settings: BrokerSettings):
        self.settings = settings
        self.connection_params = pika.ConnectionParameters(
            host=settings.host,
            port=settings.port,
            credentials=pika.PlainCredentials(settings.user, settings.password),
            heartbeat=60,
            blocked_connection_timeout=300,
        )

    def connect(self) -> BlockingConnection:
        """Establish connection with retry logic."""
        for attempt in range(1, self.settings.max_retries + 1):
            try:
                return pika.BlockingConnection(self.connection_params)
            except pika.exceptions.AMQPConnectionError:
                logger.warning(
                    "RabbitMQ not ready (attempt %d/%d), retrying in %ds…",
                    attempt,
                    self.settings.max_retries,
                    self.settings.retry_delay,
                )
                time.sleep(self.settings.retry_delay)
        raise BrokerError(
            f"Could not connect to RabbitMQ after {self.settings.max_retries} attempts."
        )

    def setup_channel(self, connection: BlockingConnection) -> BlockingChannel:
        """Declare queues and exchange on channel."""
        channel = connection.channel()
        channel.queue_declare(queue=self.settings.queue_skeleton, durable=True)
        channel.exchange_declare(
            exchange=self.settings.exchange_events,
            exchange_type="topic",
            durable=True,
        )
        channel.basic_qos(prefetch_count=1)
        return channel

    def publish_event(
        self,
        channel: BlockingChannel,
        routing_key: str,
        payload: dict[str, Any],
    ) -> None:
        """Publish an event to the ascension.events exchange."""
        channel.basic_publish(
            exchange=self.settings.exchange_events,
            routing_key=routing_key,
            body=json.dumps(payload),
            properties=pika.BasicProperties(
                content_type="application/json",
                delivery_mode=2,
            ),
        )
        logger.info("Published event %s on exchange %s", routing_key, self.settings.exchange_events)

    def start_consuming(
        self,
        channel: BlockingChannel,
        on_message_callback: Callable[[BlockingChannel, Any, Any, bytes], None],
    ) -> None:
        """Start listening for jobs on the queue."""
        channel.basic_consume(
            queue=self.settings.queue_skeleton,
            on_message_callback=on_message_callback,
            auto_ack=False,
        )
        logger.info("Consuming jobs from %s...", self.settings.queue_skeleton)
        channel.start_consuming()
