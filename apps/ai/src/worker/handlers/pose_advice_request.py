# @date 2026-11-01
# @file pose_advice_request.py
# @brief Handler of `pose.advice.requested`: LLM advice stored in the `advices` table.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.utils.broker import consume
from common.utils.errors import TransientError, with_retry
from common.utils.logger import log
from shared.models import Job, JobStatus, RoutingKey, Status
from worker._2_advice.pose_advice import PoseAdvice
from worker.handlers.failure import fail_job
from worker.runtime import get_broker, get_db, get_llm

PROGRESS_ADVICE = 90


def _llm_message(exc: Exception) -> str:
    """Fixed message per error type: never the exception text (no key, no URL)."""
    if isinstance(exc, ValueError):
        return "LLM not configured"
    if isinstance(exc, TransientError):
        return "LLM unavailable"
    return "LLM could not produce advice"


@consume(Job)
def pose_advice_request(payload: Job):
    """Generate the hints of a video and store them in ``advices.result``.

    ``job_id`` is the video id (``advices.id``). The input is the ``result`` of the
    latest successful analysis of that video; ``analyses`` is never written here.

    An LLM failure (or a missing LLM configuration) ends the advice in ``failed`` with
    a short message and the message is acked: the server relaunches it with
    ``pose.advice.requested``. Any other failure is reported once and dead-lettered
    (see ``pose_detect_request``).
    """
    log.info(f" [x] POSE_ADVICE_REQUEST: {payload}")
    job_id = payload.job_id
    broker, db = get_broker(), get_db()
    stage = "db"
    try:
        if with_retry(lambda: db.get_advice_status(job_id)) == Status.SUCCESS:
            log.info("Job %s already done, redelivery ignored", job_id)
            return
        with_retry(lambda: db.mark_advice_started(job_id))
        broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.STARTED))
        stage = "result"
        result = with_retry(lambda: db.get_video_result(job_id))
        stage = "db"
        with_retry(lambda: db.update_advice_progress(job_id, PROGRESS_ADVICE))
        broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.RUNNING))

        try:
            llm = get_llm()
            hints = with_retry(
                lambda: PoseAdvice(llm, llm.config.model).process(result.model_dump(mode="json", exclude_none=True))
            )
        except Exception as exc:  # noqa: BLE001
            log.error("Job %s: no advice generated", job_id, exc_info=exc)
            message = _llm_message(exc)
            with_retry(lambda: db.fail_advice(job_id, message))
            broker.publish(
                RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.FAILED, message=message)
            )
            return

        with_retry(lambda: db.complete_advice(job_id, hints))
        broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.SUCCESS))
    except Exception as exc:
        raise fail_job(job_id, RoutingKey.POSE_ADVICE_STATUS, stage, exc, advice=True) from exc
