# @date 2026-09-17
# @file macro.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.models.broker import Bind
from worker.handlers.pose_detect_completed import pose_detect_completed
from worker.handlers.pose_detect_request import pose_detect_request

BROKER_BINDINGS: list[Bind] = [
    Bind(queue="poses.detect", routing_key="pose.detect.requested", callback=pose_detect_request),
    Bind(queue="poses.analyze", routing_key="pose.detect.completed", callback=pose_detect_completed),
]
