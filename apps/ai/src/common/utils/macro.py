# @date 2026-11-01
# @file macro.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.models.broker import Bind
from shared.models import RoutingKey
from worker.handlers.ghost_compute_request import ghost_compute_request
from worker.handlers.hold_detect_request import hold_detect_request
from worker.handlers.pose_advice_request import pose_advice_request
from worker.handlers.pose_detect_request import pose_detect_request

BROKER_BINDINGS: list[Bind] = [
    Bind(
        queue="poses.detect",
        routing_key=RoutingKey.POSE_DETECT_REQUESTED,
        callback=pose_detect_request,
    ),
    Bind(
        queue="poses.advice",
        routing_key=RoutingKey.POSE_ADVICE_REQUESTED,
        callback=pose_advice_request,
    ),
    Bind(
        queue="holds.detect",
        routing_key=RoutingKey.HOLDS_DETECT_REQUESTED,
        callback=hold_detect_request,
    ),
    Bind(
        queue="ghosts.compute",
        routing_key=RoutingKey.GHOSTS_COMPUTE_REQUESTED,
        callback=ghost_compute_request,
    ),
]
