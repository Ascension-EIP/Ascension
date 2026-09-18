# @date 2026-09-18
# @file pose_detect_request.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import traceback

from common.utils.broker import payload_validity
from common.utils.logger import log
from shared.models import *
from worker import broker, pose_skeleton


@payload_validity
def pose_detect_request(ch, method, properties, payload):
    log.info(f" [x] POSE_DETECT_REQUEST: {payload}")
    # TODO: créer le schema pour la paylaod quej e suis censé recevoir
    job_id = payload.get("job_id")
    broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=JobStatus.PENDING))
    try:
        # TODO: avoir le lien s3 et downlaod temporairement la vidéo pour la process
        pose_skeleton.process()
        broker.publish(RoutingKey.POSE_DETECT_COMPLETED, Job(job_id=job_id))
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=JobStatus.SUCCESS))
        # TODO: créer le schéma representant celui de la db pour les résultats
        # TODO: mettre dans la db les résultats, que le worker ira fetch après avec ce job id ou autre
    except Exception:  # noqa: BLE001
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=JobStatus.FAILED, message=traceback.format_exc()))
        log.error(traceback.format_exc())
    finally:
        ch.basic_ack(delivery_tag=method.delivery_tag)


