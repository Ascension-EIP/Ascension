# @date 2026-10-25
# @file macro.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.models.broker import Bind
from shared.models import *
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
        routing_key=RoutingKey.POSE_DETECT_COMPLETED,
        callback=pose_advice_request,
    ),
    Bind(
        queue="poses.advice",
        routing_key=RoutingKey.POSE_ADVICE_REQUESTED,
        callback=pose_advice_request,
    ),
]
