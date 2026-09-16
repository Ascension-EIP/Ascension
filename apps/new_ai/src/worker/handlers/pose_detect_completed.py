# @date 2026-09-17
# @file pose_detect_completed.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.utils.broker import payload_validity
from common.utils.logger import log


@payload_validity
def pose_detect_completed(ch, method, properties, payload):
    log.info(f" [x] POSE_DETECT_COMPLETED: {payload}")
    # TODO: traiter le job ici, puis acquitter le message.
    ch.basic_ack(delivery_tag=method.delivery_tag)
