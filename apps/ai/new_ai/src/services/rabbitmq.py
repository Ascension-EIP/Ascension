# @date 2026-09-10
# @file rabbitmq.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os

import pika
from pika import BlockingConnection
from pika.adapters.blocking_connection import BlockingChannel

from common.models.broker import BrokerModel
from common.utils.errors import throw_if_none


class Broker:
    def __init__(self):
        self.config: BrokerModel | None = None
        self.connection: BlockingConnection | None = None
        self.channel: BlockingChannel | None = None

    def setup_config(self):
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

    def connect(self):
        if not self.config:
            self.setup_config()

        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=self.config.host,
                port=self.config.port,
                credentials=pika.PlainCredentials(
                    self.config.user, self.config.password
                ),
            )
        )
        self.channel = self.connection.channel()
