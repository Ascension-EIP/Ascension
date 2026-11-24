# @date 2026-11-24
# @file hold_detect_request.py
# @brief Handler of `holds.detect.requested`: download the route photo, detect its holds, store them.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
from contextlib import ExitStack

from common.utils.broker import consume
from common.utils.errors import PermanentError, with_retry
from common.utils.logger import log
from shared.models import HoldDetectRequest, JobStatus, RoutingKey, Status
from worker.handlers.failure import fail_job
from worker.runtime import get_broker, get_db, get_hold_segmenter, get_storage

PROGRESS_DETECTION_START = 10


@consume(HoldDetectRequest)
def hold_detect_request(payload: HoldDetectRequest):
    """Detect the holds of a route photo and store one ``holds`` row per hold.

    ``job_id`` is ``routes.id``. The job lifecycle is written in the ``routes`` row
    (``status``, ``progress``, ``error``), like ``analyses`` for a pose analysis.
    Network operations are retried here; the detection itself never is. A definitive
    failure is reported once, then dead-lettered (see ``pose_detect_request``).
    """
    log.info(f" [x] HOLD_DETECT_REQUEST: {payload}")
    route_id = payload.job_id
    broker, db = get_broker(), get_db()
    stage = "db"
    try:
        if with_retry(lambda: db.get_route_status(route_id)) == Status.SUCCESS:
            log.info("Route %s already detected, redelivery ignored", route_id)
            return
        # Lazy: ONNX Runtime and the model are only loaded by the first hold job.
        from worker._3_holds._0_hold_detect import detect_holds

        stage = "model"
        try:
            segmenter = get_hold_segmenter()
        except FileNotFoundError as exc:
            raise PermanentError(str(exc)) from exc

        stage = "db"
        with_retry(lambda: db.mark_route_started(route_id))
        broker.publish(RoutingKey.HOLDS_DETECT_STATUS, JobStatus(job_id=route_id, status=Status.STARTED))
        with_retry(lambda: db.update_route_progress(route_id, PROGRESS_DETECTION_START))
        broker.publish(RoutingKey.HOLDS_DETECT_STATUS, JobStatus(job_id=route_id, status=Status.RUNNING))

        with ExitStack() as stack:
            stage = "photo"
            path = with_retry(lambda: stack.enter_context(get_storage().download_temp(payload.object_key)))
            stage = "holds"
            result = detect_holds(path, segmenter)
        log.info("Route %s: %d holds detected", route_id, len(result.holds))

        stage = "db"
        with_retry(lambda: db.save_holds(route_id, result))
        with_retry(lambda: db.complete_route(route_id))
        broker.publish(RoutingKey.HOLDS_DETECT_STATUS, JobStatus(job_id=route_id, status=Status.SUCCESS))
    except Exception as exc:
        raise fail_job(route_id, RoutingKey.HOLDS_DETECT_STATUS, stage, exc, table="routes") from exc
