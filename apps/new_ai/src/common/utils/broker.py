# @date 2026-09-17
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
    """Décode le corps JSON avant d'appeler le consommateur.

    Le callback enveloppé est appelé avec ``(channel, method, properties,
    payload)`` : le dernier argument est le JSON désérialisé, pas les octets
    bruts transmis par pika.
    """

    @functools.wraps(func)
    def validator(ch, method, properties, body):
        try:
            payload = json.loads(body.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as e:
            log.error("Échec du pré-traitement (JSON invalide): %s", e)
            # Rejet immédiat si le prérequis échoue
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            return None

        return func(ch, method, properties, payload)

    return validator


