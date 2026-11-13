# @date 2026-11-01
# @file pose_advice_request.py
# @brief Handler of `pose.detect.completed` and `pose.advice.requested`: LLM advice, end of the job.
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
    """Generate the hints from the stored ``result`` and end the analysis.

    Also runs as a relaunch on an analysis that is already ``success``: it then
    keeps the status, and keeps the previous hints if the LLM fails again.

    An LLM failure (or a missing LLM configuration) is not a job failure: the
    analysis ends in ``success`` with no hints, ``pose.advice.status`` says
    ``failed`` and the message is acked. Any other failure is reported once and
    dead-lettered (see ``pose_detect_request``).
    """
    log.info(f" [x] POSE_ADVICE_REQUEST: {payload}")
    job_id = payload.job_id
    broker, db = get_broker(), get_db()
    already_done = False
    stage = "db"
    try:
        broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.STARTED))
        stage = "result"
        result = with_retry(lambda: db.get_result(job_id))
        stage = "db"
        already_done = with_retry(lambda: db.get_status(job_id)) == Status.SUCCESS
        if not already_done:
            with_retry(lambda: db.update_progress(job_id, PROGRESS_ADVICE))
            broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.RUNNING))

        try:
            llm = get_llm()
            hints = with_retry(
                lambda: PoseAdvice(llm, llm.config.model).process(result.model_dump(mode="json", exclude_none=True))
            )
        except Exception as exc:  # noqa: BLE001
            log.error("Job %s: no advice generated", job_id, exc_info=exc)
            if not already_done:
                with_retry(lambda: db.complete(job_id))
            broker.publish(
                RoutingKey.POSE_ADVICE_STATUS,
                JobStatus(job_id=job_id, status=Status.FAILED, message=_llm_message(exc)),
            )
            return

        with_retry(lambda: db.save_hints(job_id, hints))
        if not already_done:
            with_retry(lambda: db.complete(job_id))
        broker.publish(RoutingKey.POSE_ADVICE_STATUS, JobStatus(job_id=job_id, status=Status.SUCCESS))
    except Exception as exc:
        # An analysis already in `success` keeps its status, result and hints.
        raise fail_job(job_id, RoutingKey.POSE_ADVICE_STATUS, stage, exc, mark_db=not already_done) from exc
