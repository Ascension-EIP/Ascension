# @date 2026-11-01
# @file rabbitmq.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import functools
import os
import threading
import time
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Self

import pika
from pika import BlockingConnection
from pika.adapters.blocking_connection import BlockingChannel

from common.models.broker import BrokerModel
from common.utils.errors import throw_if_none
from common.utils.logger import log
from common.utils.macro import BROKER_BINDINGS

DLX = "events.dlx"


class Broker:
    def __init__(self):
        self.config: BrokerModel | None = None
        self.connection: BlockingConnection | None = None
        self.channel: BlockingChannel | None = None
        # One job at a time per process: scale by adding replicas.
        self._executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="job")
        self._io_thread: int | None = None

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
        log.info("Broker config: %s:%d", self.config.host, self.config.port)
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
            except Exception as e:  # noqa: BLE001
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
        # Global prefetch of 1: a single unacked message for the whole channel.
        self.channel.basic_qos(prefetch_count=1, global_qos=True)
        self.channel.exchange_declare(
            exchange=self.config.exchange,
            exchange_type="topic",
            durable=True,
        )
        self.channel.exchange_declare(exchange=DLX, exchange_type="direct", durable=True)
        for queue in dict.fromkeys(bind.queue for bind in BROKER_BINDINGS):
            dlq = f"{queue}.dlq"
            self.channel.queue_declare(queue=dlq, durable=True)
            self.channel.queue_bind(queue=dlq, exchange=DLX, routing_key=dlq)
            self.channel.queue_declare(
                queue=queue,
                durable=True,
                arguments={
                    "x-dead-letter-exchange": DLX,
                    "x-dead-letter-routing-key": dlq,
                },
            )
        for bind in BROKER_BINDINGS:
            self.channel.queue_bind(
                queue=bind.queue,
                routing_key=bind.routing_key,
                exchange=self.config.exchange,
            )
        return self

    def start_consuming(self) -> Self:
        """Start listening for jobs: one consumer per queue, jobs run in a thread."""
        callbacks: dict[str, Callable] = {}
        for bind in BROKER_BINDINGS:
            if callbacks.setdefault(bind.queue, bind.callback) is not bind.callback:
                raise ValueError(f"Queue {bind.queue} is bound with different callbacks.")
        for queue, callback in callbacks.items():
            self.channel.basic_consume(queue=queue, on_message_callback=callback, auto_ack=False)
            log.info("Consuming jobs from %s...", queue)
        self._io_thread = threading.get_ident()
        # ponytail: no auto-reconnect. If the connection drops, this raises, the
        # process exits non-zero and the orchestrator restarts it (unacked
        # messages are redelivered). Add a reconnect loop only if restarts hurt.
        try:
            self.channel.start_consuming()
        finally:
            self._executor.shutdown(wait=False, cancel_futures=True)
        return self

    def submit(self, fn: Callable[..., None], *args: Any) -> None:
        """Run ``fn(*args)`` in the job thread, leaving the I/O thread free."""
        self._executor.submit(fn, *args)

    def _on_io_thread(self, fn: Callable[[], None]) -> None:
        """Run ``fn`` on the pika I/O thread; pika channels are not thread-safe."""
        if self._io_thread is None or threading.get_ident() == self._io_thread:
            fn()
        else:
            # Fire and forget: if the connection is down, the process is about to exit anyway.
            self.connection.add_callback_threadsafe(fn)

    def ack(self, delivery_tag: int) -> None:
        self._on_io_thread(functools.partial(self.channel.basic_ack, delivery_tag=delivery_tag))

    def nack(self, delivery_tag: int) -> None:
        """Reject without requeue: the message goes to the queue's dead-letter queue."""
        self._on_io_thread(functools.partial(self.channel.basic_nack, delivery_tag=delivery_tag, requeue=False))

    def publish(self, routing_key: str, payload) -> Self:
        """Publish a message; safe to call from the job thread."""
        self._on_io_thread(
            functools.partial(
                self.channel.basic_publish,
                exchange=self.config.exchange,
                routing_key=routing_key,
                body=payload.model_dump_json().encode("utf-8"),
                properties=pika.BasicProperties(content_type="application/json", delivery_mode=2),
            )
        )
        log.info("Published to %s: %s", routing_key, payload)
        return self
