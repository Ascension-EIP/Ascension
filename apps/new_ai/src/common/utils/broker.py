# @date 2026-09-27
# @file broker.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import functools
import json
from collections.abc import Callable
from typing import Any

from common.utils.logger import log


def payload_validity(func: Callable[..., Any]) -> Callable[..., Any]:
    """Decode the JSON body before calling the consumer.

    The wrapped callback is called with ``(channel, method, properties,
    payload)``: the last argument is the deserialized JSON, not the raw bytes
    sent by pika.
    """

    @functools.wraps(func)
    def validator(ch, method, properties, body):
        try:
            payload = json.loads(body.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as e:
            log.error("Pre-processing failed (invalid JSON): %s", e)
            # Reject immediately when the prerequisite fails
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            return None

        return func(ch, method, properties, payload)

    return validator


