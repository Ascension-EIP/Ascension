# @date 2026-11-01
# @file failure.py
# @brief Definitive-failure path shared by the handlers.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.utils.errors import PermanentError, TransientError
from common.utils.logger import log
from shared.models import JobStatus, RoutingKey, Status
from worker.runtime import get_broker, get_db

# (stage, is_transient) -> short message stored in the database and sent in statuses.
_MESSAGES = {
    ("storage", True): "Storage unavailable",
    ("storage", False): "Video not found",
    ("pose", True): "Database unavailable",  # only the progress writes can be transient here
    ("pose", False): "Unreadable video",
    ("db", True): "Database unavailable",
    ("db", False): "Analysis not found",
    ("result", False): "Result not found",
}


def short_message(stage: str, exc: Exception) -> str:
    """Short, secret-free message for a failed ``stage``; the details stay in the logs."""
    if isinstance(exc, (TransientError, PermanentError)):
        return _MESSAGES.get((stage, isinstance(exc, TransientError)), "Analysis failed")
    return "Analysis failed"


def fail_job(job_id: str, status_key: RoutingKey, stage: str, exc: Exception, mark_db: bool = True) -> PermanentError:
    """Report a definitive failure once and return the error to raise.

    Writes ``failed`` in the database (unless ``mark_db`` is false), publishes the
    ``failed`` status with a short message, and logs the traceback. Raising the
    returned `PermanentError` makes the ``consume`` wrapper dead-letter the message
    without retrying.
    """
    message = short_message(stage, exc)
    log.error("Job %s failed (%s): %s", job_id, stage, message, exc_info=exc)
    if mark_db:
        try:
            get_db().fail(job_id, message)
        except Exception:  # noqa: BLE001
            log.exception("Job %s: could not write the failure in the database", job_id)
    try:
        get_broker().publish(status_key, JobStatus(job_id=job_id, status=Status.FAILED, message=message))
    except Exception:  # noqa: BLE001
        log.exception("Job %s: could not publish the failed status", job_id)
    return PermanentError(message)
