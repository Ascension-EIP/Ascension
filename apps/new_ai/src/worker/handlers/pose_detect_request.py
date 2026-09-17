# @date 2026-09-17
# @file pose_detect_request.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import traceback

from common.models.broker import RoutingKey
from common.models.job import Job, JobStatus, JobStatusModel
from common.utils.broker import payload_validity
from common.utils.logger import log
from worker import broker, pose_skeleton


@payload_validity
def pose_detect_request(ch, method, properties, payload):
    log.info(f" [x] POSE_DETECT_REQUEST: {payload}")
    job_id = payload.get("job_id")
    # TODO: traiter le job ici, puis acquitter le message.
    broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatusModel(job_id=job_id, status=JobStatus.PENDING))
    try:
        pose_skeleton.process()
        broker.publish(RoutingKey.POSE_DETECT_COMPLETED, Job(job_id=job_id))
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatusModel(job_id=job_id, status=JobStatus.SUCCESS))
    except Exception:  # noqa: BLE001
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatusModel(job_id=job_id, status=JobStatus.FAILED, message=traceback.format_exc()))
        log.error(traceback.format_exc())
    finally:
        ch.basic_ack(delivery_tag=method.delivery_tag)


