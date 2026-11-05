# @date 2026-11-01
# @file broker.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import functools
from collections.abc import Callable
from typing import Any

from pydantic import BaseModel, ValidationError

from common.utils.errors import with_retry
from common.utils.logger import log
from worker.runtime import get_broker


def consume(model: type[BaseModel]) -> Callable[[Callable[[Any], None]], Callable[..., None]]:
    """Turn ``handler(payload)`` into a pika consumer callback.

    The body is validated against ``model``. An invalid payload is rejected at
    once (``nack`` without requeue, so it goes to the dead-letter queue). A valid
    one is run in the job thread, so the I/O thread keeps answering heartbeats:

    - success: ``ack``;
    - `TransientError`: retried by `with_retry`, then ``nack`` (dead letter);
    - `PermanentError` or any other exception: ``nack`` right away, traceback in
      the logs.

    The handler stays responsible for writing ``failed`` and publishing the
    status; this wrapper only handles the message lifecycle.
    """

    def decorator(handler: Callable[[Any], None]) -> Callable[..., None]:
        @functools.wraps(handler)
        def callback(ch, method, properties, body):
            broker = get_broker()
            tag = method.delivery_tag
            try:
                payload = model.model_validate_json(body)
            except ValidationError as e:
                log.error("%s: invalid %s payload, rejected: %s", handler.__name__, model.__name__, e)
                broker.nack(tag)
                return
            broker.submit(_run, broker, handler, payload, tag)

        return callback

    return decorator


def _run(broker, handler: Callable[[Any], None], payload: Any, tag: int) -> None:
    """Run in the job thread: execute the handler, then ack or nack."""
    try:
        with_retry(lambda: handler(payload))
    except Exception:  # noqa: BLE001
        log.exception("%s failed, message dead-lettered", handler.__name__)
        broker.nack(tag)
    else:
        broker.ack(tag)
