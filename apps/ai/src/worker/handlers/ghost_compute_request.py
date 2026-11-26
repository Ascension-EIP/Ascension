# @date 2026-11-25
# @file ghost_compute_request.py
# @brief Handler of `ghosts.compute.requested`: read the ghost and its route, compute the beta and the postures, store the path.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.utils.broker import consume
from common.utils.errors import PermanentError, with_retry
from common.utils.logger import log
from shared.models import (
    BetaPreference,
    GhostComputeRequest,
    JobStatus,
    RoutingKey,
    Status,
)
from worker.handlers.failure import fail_job
from worker.runtime import get_broker, get_db

PROGRESS_START = 10
PROGRESS_INPUT_READ = 30


@consume(GhostComputeRequest)
def ghost_compute_request(payload: GhostComputeRequest):
    """Compute the ghost of a route and store ``ghosts.path``.

    ``job_id`` is ``ghosts.id``. The job lifecycle is written in the ``ghosts`` row (``status``, ``progress``,
    ``error``), like ``routes`` for a hold detection. The route must carry a wall plane (written by the hold
    detection). No beta, a missing wall or invalid stored data are permanent failures with a short message.
    Database operations are retried here; the computation itself never is.
    """
    log.info(f" [x] GHOST_COMPUTE_REQUEST: {payload}")
    ghost_id = payload.job_id
    broker, db = get_broker(), get_db()
    stage = "db"
    try:
        if with_retry(lambda: db.get_ghost_status(ghost_id)) == Status.SUCCESS:
            log.info("Ghost %s already computed, redelivery ignored", ghost_id)
            return
        # Lazy: NumPy and OpenCV are only loaded by the first ghost job.
        from worker._4_ghost._4_ghost import (
            compute_ghost,
            photo_holds_from_dicts,
            validate_wall,
        )

        with_retry(lambda: db.mark_ghost_started(ghost_id))
        broker.publish(RoutingKey.GHOSTS_COMPUTE_STATUS, JobStatus(job_id=ghost_id, status=Status.STARTED))
        with_retry(lambda: db.update_ghost_progress(ghost_id, PROGRESS_START))
        broker.publish(RoutingKey.GHOSTS_COMPUTE_STATUS, JobStatus(job_id=ghost_id, status=Status.RUNNING))

        stage = "input"
        data = with_retry(lambda: db.get_ghost_input(ghost_id))
        stage = "wall"
        if data.wall is None:
            raise PermanentError("wall geometry missing")
        stage = "wall_shape"
        validate_wall(data.wall)
        stage = "input"
        holds = photo_holds_from_dicts(data.holds)
        stage = "db"
        with_retry(lambda: db.update_ghost_progress(ghost_id, PROGRESS_INPUT_READ))

        stage = "ghost"
        path = compute_ghost(
            holds,
            data.wall,
            data.feet_free,
            data.selected_ids,
            data.morphology,
            payload.preference or BetaPreference.EASY,
            (data.image_width, data.image_height),
        )
        log.info("Ghost %s: %d steps", ghost_id, len(path.steps))

        stage = "db"
        with_retry(lambda: db.complete_ghost(ghost_id, path))
        broker.publish(RoutingKey.GHOSTS_COMPUTE_STATUS, JobStatus(job_id=ghost_id, status=Status.SUCCESS))
    except Exception as exc:
        raise fail_job(ghost_id, RoutingKey.GHOSTS_COMPUTE_STATUS, stage, exc, table="ghosts") from exc
