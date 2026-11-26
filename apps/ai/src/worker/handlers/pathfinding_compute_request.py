# @date 2026-11-25
# @file pathfinding_compute_request.py
# @brief Handler of `pathfinding.compute.requested`: read the `pathfindings` row and its route, compute the beta and the postures, store the result.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from common.utils.broker import consume
from common.utils.errors import PermanentError, with_retry
from common.utils.logger import log
from shared.models import (
    BetaPreference,
    JobStatus,
    PathfindingComputeRequest,
    RoutingKey,
    Status,
)
from worker.handlers.failure import fail_job
from worker.runtime import get_broker, get_db

PROGRESS_START = 10
PROGRESS_INPUT_READ = 30


@consume(PathfindingComputeRequest)
def pathfinding_compute_request(payload: PathfindingComputeRequest):
    """Compute the beta and the postures of a climber on a route and store ``pathfindings.result``.

    ``job_id`` is ``pathfindings.id``: the pathfinding result is the content of
    ``pathfindings.result``. The job lifecycle is written in the ``pathfindings`` row (``status``, ``progress``,
    ``error``), like ``routes`` for a hold detection. The route must carry a wall plane (written by the hold
    detection). No beta, a missing wall or invalid stored data are permanent failures with a short message.
    Database operations are retried here; the computation itself never is.
    """
    log.info(f" [x] PATHFINDING_COMPUTE_REQUEST: {payload}")
    pathfinding_id = payload.job_id
    broker, db = get_broker(), get_db()
    stage = "db"
    try:
        if with_retry(lambda: db.get_pathfinding_status(pathfinding_id)) == Status.SUCCESS:
            log.info("Pathfinding %s already computed, redelivery ignored", pathfinding_id)
            return
        # Lazy: NumPy and OpenCV are only loaded by the first pathfinding job.
        from worker._4_pathfinding._4_pathfinding import (
            compute_pathfinding,
            photo_holds_from_dicts,
            validate_wall,
        )

        with_retry(lambda: db.mark_pathfinding_started(pathfinding_id))
        broker.publish(RoutingKey.PATHFINDING_COMPUTE_STATUS, JobStatus(job_id=pathfinding_id, status=Status.STARTED))
        with_retry(lambda: db.update_pathfinding_progress(pathfinding_id, PROGRESS_START))
        broker.publish(RoutingKey.PATHFINDING_COMPUTE_STATUS, JobStatus(job_id=pathfinding_id, status=Status.RUNNING))

        stage = "input"
        data = with_retry(lambda: db.get_pathfinding_input(pathfinding_id))
        stage = "wall"
        if data.wall is None:
            raise PermanentError("wall geometry missing")
        stage = "wall_shape"
        validate_wall(data.wall)
        stage = "input"
        holds = photo_holds_from_dicts(data.holds)
        stage = "db"
        with_retry(lambda: db.update_pathfinding_progress(pathfinding_id, PROGRESS_INPUT_READ))

        stage = "pathfinding"
        result = compute_pathfinding(
            holds,
            data.wall,
            data.feet_free,
            data.selected_ids,
            data.morphology,
            payload.preference or BetaPreference.EASY,
            (data.image_width, data.image_height),
        )
        log.info("Pathfinding %s: %d steps", pathfinding_id, len(result.steps))

        stage = "db"
        with_retry(lambda: db.complete_pathfinding(pathfinding_id, result))
        broker.publish(RoutingKey.PATHFINDING_COMPUTE_STATUS, JobStatus(job_id=pathfinding_id, status=Status.SUCCESS))
    except Exception as exc:
        raise fail_job(pathfinding_id, RoutingKey.PATHFINDING_COMPUTE_STATUS, stage, exc, table="pathfindings") from exc
