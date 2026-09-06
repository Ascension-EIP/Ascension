# @date 2026-09-07
# @file runner.py
# @brief Worker lifecycle runner, resilient connection loop, and signal handling.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Worker lifecycle runner and loop."""

import json
import logging
import sys
import time

import pika

from src.config.exceptions import ConfigurationError
from src.config.settings import Settings
from src.config.validator import load_settings
from src.infrastructure.database import AnalysisRepository
from src.infrastructure.messaging import RabbitMQClient
from src.infrastructure.storage import StorageService
from src.worker.coordinator import JobCoordinator
from src.worker.pid import acquire_pid_lock

logger = logging.getLogger("ai-worker")


def run_worker(settings: Settings | None = None) -> int:
    """Validate settings, initialize services, and run the RabbitMQ worker loop."""
    try:
        if settings is None:
            settings = load_settings(standalone=False)
    except ConfigurationError as e:
        # Print clearly and stop immediately (Fail-Fast)
        print(f"\n[FATAL CONFIGURATION ERROR] {e}\n", file=sys.stderr)
        return 1

    logging.basicConfig(
        level=getattr(logging, settings.worker.log_level, logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
        force=True,
    )

    logger.info("Starting Ascension AI Worker…")
    acquire_pid_lock(settings.worker.pid_file)

    # Safe logging of masked environment
    logger.info(
        "Active Configuration:\n%s",
        json.dumps(settings.to_masked_dict(), indent=2),
    )

    storage = StorageService(settings.storage)
    db_repo = AnalysisRepository(settings.database)
    messaging = RabbitMQClient(settings.broker)
    coordinator = JobCoordinator(settings, storage, db_repo, messaging)

    while True:
        try:
            connection = messaging.connect()
            channel = messaging.setup_channel(connection)

            logger.info("Worker ready — waiting for jobs on '%s'...", settings.broker.queue_skeleton)
            messaging.start_consuming(
                channel=channel,
                on_message_callback=coordinator.handle_message,
            )

        except (
            pika.exceptions.ConnectionClosedByBroker,
            pika.exceptions.AMQPChannelError,
            pika.exceptions.AMQPConnectionError,
        ) as exc:
            logger.warning(
                "RabbitMQ connection lost (%s), reconnecting in %ds…",
                exc,
                settings.broker.retry_delay,
            )
            time.sleep(settings.broker.retry_delay)
            continue
        except KeyboardInterrupt:
            logger.info("Worker stopped by user.")
            break
        except Exception:
            logger.exception("Unexpected worker failure, restarting in %ds…", settings.broker.retry_delay)
            time.sleep(settings.broker.retry_delay)

    return 0
