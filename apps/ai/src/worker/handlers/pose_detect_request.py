# @date 2026-11-02
# @file pose_detect_request.py
# @brief Handler of `pose.detect.requested`: download, analyse, store the result.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from contextlib import ExitStack

from common.utils.broker import consume
from common.utils.errors import with_retry
from common.utils.logger import log
from shared.models import Job, JobStatus, PoseDetectRequest, RoutingKey, Status
from worker.handlers.failure import fail_job
from worker.runtime import get_broker, get_db, get_storage

PROGRESS_SKELETON_START = 5
PROGRESS_SKELETON_END = 70
PROGRESS_STEP = 5
PROGRESS_STEPS_DONE = 80


@consume(PoseDetectRequest)
def pose_detect_request(payload: PoseDetectRequest):
    """Analyse the video and store ``result``; the analysis stays ``running`` until advice.

    Network operations are retried here (``with_retry``); the MediaPipe run never is.
    A definitive failure is reported once, then `PermanentError` is raised so the
    ``consume`` wrapper dead-letters the message without a second round of retries.
    """
    log.info(f" [x] POSE_DETECT_REQUEST: {payload}")
    job_id = payload.job_id
    broker, db = get_broker(), get_db()
    stage = "db"
    try:
        if with_retry(lambda: db.get_status(job_id)) == Status.SUCCESS:
            log.info("Job %s already done, redelivery ignored", job_id)
            return
        # Lazy: this import loads MediaPipe.
        from worker._1_mediapipe._0_pose_detect import detect_pose

        with_retry(lambda: db.mark_started(job_id))
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=Status.STARTED))
        with_retry(lambda: db.update_progress(job_id, PROGRESS_SKELETON_START))
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=Status.RUNNING))

        written = PROGRESS_SKELETON_START

        def on_progress(percent: int) -> None:
            # At most one database write per 5% of progress. A failed write must never
            # abort (or stall in retries) a MediaPipe run that may have been going for minutes.
            nonlocal written
            scaled = PROGRESS_SKELETON_START + percent * (PROGRESS_SKELETON_END - PROGRESS_SKELETON_START) // 100
            if scaled >= written + PROGRESS_STEP:
                written = scaled
                try:
                    db.update_progress(job_id, scaled)
                except Exception as exc:  # noqa: BLE001
                    log.warning("Job %s: progress %d%% not written, continuing: %s", job_id, scaled, exc)

        with ExitStack() as stack:
            stage = "storage"
            path = with_retry(lambda: stack.enter_context(get_storage().download_temp(payload.object_key)))
            stage = "pose"
            result = detect_pose(str(path), on_progress=on_progress)

        stage = "db"
        # Filter and metrics (75) and movements (80) are one fast call in `detect_pose`.
        with_retry(lambda: db.update_progress(job_id, PROGRESS_STEPS_DONE))
        with_retry(lambda: db.save_result(job_id, result))
        broker.publish(RoutingKey.POSE_DETECT_STATUS, JobStatus(job_id=job_id, status=Status.SUCCESS))
        broker.publish(RoutingKey.POSE_DETECT_COMPLETED, Job(job_id=job_id))
    except Exception as exc:
        raise fail_job(job_id, RoutingKey.POSE_DETECT_STATUS, stage, exc) from exc
