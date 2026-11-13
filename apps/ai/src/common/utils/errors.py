# @date 2026-11-01
# @file errors.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import time
from collections.abc import Callable
from typing import TypeVar

from pydantic import BaseModel

T = TypeVar("T")


def throw_if_none(model: BaseModel):
    fields_with_none = [
        field for field, value in model.model_dump().items() if value is None
    ]
    if fields_with_none:
        raise ValueError(f"fields: {fields_with_none} are mandatory.")


class TransientError(Exception):
    """A failure that may succeed on retry (network, storage or database outage)."""


class PermanentError(Exception):
    """A failure that retrying cannot fix (invalid input, missing object)."""


def with_retry(func: Callable[[], T], attempts: int = 3, base_delay: float = 2.0) -> T:
    """Call ``func``, retrying only on `TransientError` with exponential backoff.

    Waits ``base_delay``, then ``2 * base_delay``, and so on between attempts.
    The last `TransientError` is raised once ``attempts`` is exhausted; any other
    exception propagates immediately.
    """
    for attempt in range(1, attempts + 1):
        try:
            return func()
        except TransientError:
            if attempt == attempts:
                raise
            time.sleep(base_delay * 2 ** (attempt - 1))
    raise ValueError("attempts must be >= 1")
