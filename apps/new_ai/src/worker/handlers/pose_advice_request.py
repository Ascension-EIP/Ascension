# @date 2026-09-17
# @file pose_advice_request.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import traceback

from common.models.broker import RoutingKey
from common.models.job import JobStatus, JobStatusModel
from common.utils.broker import payload_validity
from common.utils.logger import log
from worker import broker


@payload_validity
def pose_advice_request(ch, method, properties, payload):
    log.info(f" [x] POSE_ADVICE_REQUEST: {payload}")
    job_id = payload.get("job_id")
    broker.publish(
        RoutingKey.POSE_ADVICE_STATUS,
        JobStatusModel(job_id=job_id, status=JobStatus.PENDING),
    )
    try:
        # pose_advice.process()
        broker.publish(
            RoutingKey.POSE_ADVICE_STATUS,
            JobStatusModel(job_id=job_id, status=JobStatus.SUCCESS),
        )
    except Exception:  # noqa: BLE001
        broker.publish(
            RoutingKey.POSE_ADVICE_STATUS,
            JobStatusModel(
                job_id=job_id, status=JobStatus.FAILED, message=traceback.format_exc()
            ),
        )
        log.error(traceback.format_exc())
    finally:
        ch.basic_ack(delivery_tag=method.delivery_tag)
