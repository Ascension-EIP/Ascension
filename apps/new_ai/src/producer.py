# @date 2026-09-17
# @file producer.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Mini producer to manually test the new_ai worker: publishes a fake
message on each routing key bound in common.utils.macro.BROKER_BINDINGS.
"""

import json

import pika

from common.utils.logger import log
from common.utils.macro import BROKER_BINDINGS
from services.rabbitmq import Broker

PAYLOADS = {
    "pose.detect.requested": {"job_id": "test-job-1", "video_url": "s3://bucket/video.mp4"},
    "pose.detect.completed": {"job_id": "test-job-1", "result_url": "s3://bucket/result.json"},
}


def main() -> None:
    broker = Broker().setup_config().connect().setup_channel()

    for bind in BROKER_BINDINGS:
        payload = PAYLOADS[bind.routing_key]
        broker.channel.basic_publish(
            exchange=broker.config.exchange,
            routing_key=bind.routing_key,
            body=json.dumps(payload).encode("utf-8"),
            properties=pika.BasicProperties(content_type="application/json", delivery_mode=2),
        )
        log.info("Published to %s: %s", bind.routing_key, payload)

    broker.connection.close()


if __name__ == "__main__":
    main()
