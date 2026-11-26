# @date 2026-11-01
# @file producer.py
# @brief Stand-in for the Go server: seeds a test analysis and publishes worker jobs.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Stand-in for the Go server, until it publishes on the worker queues.

Usage (from ``apps/ai``, or ``moon run ai:producer -- <args>``)::

    uv run python src/producer.py seed --video resources/example-2.mp4
    uv run python src/producer.py detect --job-id <id> --object-key <key>
    uv run python src/producer.py advice --job-id <id>
    uv run python src/producer.py seed-route --image path/to/wall.jpg
    uv run python src/producer.py holds --job-id <route_id> --object-key <key>
    uv run python src/producer.py seed-pathfinding --route-id <route_id> [--height 175 --arm-span 178]
    uv run python src/producer.py pathfinding --job-id <pathfinding_id> [--preference easy]

Messages are the generated types of ``shared.models``.
"""

import argparse
import sys
from pathlib import Path
from typing import NamedTuple
from uuid import uuid4

from dotenv import load_dotenv

from common.utils.errors import PermanentError
from common.utils.logger import log
from services.postgresql import PostgreSQL
from services.rabbitmq import Broker
from services.rustfs import RustFS
from shared.models import (
    BetaPreference,
    ClimberMorphology,
    HoldDetectRequest,
    Job,
    PathfindingComputeRequest,
    PoseDetectRequest,
    RoutingKey,
)


class SeededRoute(NamedTuple):
    route_id: str  # job id of `holds.detect.requested`
    object_key: str
    user_id: str


class SeededPathfinding(NamedTuple):
    pathfinding_id: str  # job id of `pathfinding.compute.requested`
    user_id: str


class Seeded(NamedTuple):
    job_id: str
    object_key: str
    user_id: str
    video_id: str  # `advices.id`: the job id of the advice


def _connect(db: PostgreSQL | None, storage: RustFS | None) -> tuple[PostgreSQL, RustFS]:
    """Connect to the database and the storage; create the bucket if missing (the worker never does it)."""
    db = db or PostgreSQL().setup_config().connect()
    storage = storage or RustFS().setup_config()
    if storage.client is None:
        try:
            storage.connect()
        except PermanentError:
            # `connect` builds the client before checking the bucket, so it is usable here.
            storage.client.create_bucket(Bucket=storage.config.bucket)
    return db, storage


def _seed_user(db: PostgreSQL, name: str) -> str:
    return db.connection.execute(
        "INSERT INTO users (username, first_name, last_name, email, password_hash)"
        " VALUES (%s, 'Seed', 'Seed', %s, 'x') RETURNING id",
        (name, f"{name}@example.com"),
    ).fetchone()[0]


def seed(video: str, db: PostgreSQL | None = None, storage: RustFS | None = None) -> Seeded:
    """Create a user, a video row, a `pending` analysis and a `pending` advice, and upload ``video``.

    The bucket is created if missing (the worker never does it), so this runs
    without the Go server. Everything is named after a unique suffix.
    """
    db, storage = _connect(db, storage)
    name = f"seed{uuid4().hex[:12]}"
    object_key = f"seed/{name}{Path(video).suffix}"
    storage.client.upload_file(video, storage.config.bucket, object_key)
    user = _seed_user(db, name)
    video_id = db.connection.execute(
        "INSERT INTO videos (user_id, object_key, content_type) VALUES (%s, %s, 'video/mp4') RETURNING id",
        (user, object_key),
    ).fetchone()[0]
    job_id = db.connection.execute("INSERT INTO analyses (video_id) VALUES (%s) RETURNING id", (video_id,)).fetchone()[0]
    db.connection.execute("INSERT INTO advices (id) VALUES (%s)", (video_id,))  # the server does it on `POST /advices/:id`
    return Seeded(str(job_id), object_key, str(user), str(video_id))


def seed_route(image: str, db: PostgreSQL | None = None, storage: RustFS | None = None) -> SeededRoute:
    """Create a user and a `pending` route, and upload its photo ``image``.

    The photo size is left at 0: the worker writes the real size with the holds, as
    the server may not know it when it creates the route.
    """
    db, storage = _connect(db, storage)
    name = f"seed{uuid4().hex[:12]}"
    object_key = f"seed/{name}{Path(image).suffix}"
    storage.client.upload_file(image, storage.config.bucket, object_key)
    user = _seed_user(db, name)
    route_id = db.connection.execute(
        "INSERT INTO routes (user_id, image_object_key, image_width, image_height) VALUES (%s, %s, 0, 0) RETURNING id",
        (user, object_key),
    ).fetchone()[0]
    return SeededRoute(str(route_id), object_key, str(user))


def seed_pathfinding(route_id: str, morphology: ClimberMorphology | None = None, db: PostgreSQL | None = None) -> SeededPathfinding:
    """Create a `pending` pathfinding on an existing route, for the user of the route.

    The pathfinding holds no `pathfinding_holds` row: every usable hold of the route is then part of its route.
    """
    db = db or PostgreSQL().setup_config().connect()
    morphology = morphology or ClimberMorphology(height_cm=175, arm_span_cm=178)
    row = db.connection.execute("SELECT user_id FROM routes WHERE id = %s", (route_id,)).fetchone()
    if row is None:
        raise ValueError(f"no such route: {route_id}")
    pathfinding_id = db.connection.execute(
        "INSERT INTO pathfindings (route_id, user_id, morphology) VALUES (%s, %s, %s::jsonb) RETURNING id",
        (route_id, row[0], morphology.model_dump_json(exclude_none=True)),
    ).fetchone()[0]
    return SeededPathfinding(str(pathfinding_id), str(row[0]))


def publish(routing_key: RoutingKey, payload: Job | PoseDetectRequest | HoldDetectRequest | PathfindingComputeRequest) -> None:
    broker = Broker().setup_config().connect().setup_channel()
    try:
        broker.publish(routing_key, payload)
    finally:
        broker.connection.close()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="producer", description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("seed", help="Create a test user, video and analysis; upload the video; print job_id and object_key.")
    p.add_argument("--video", required=True)
    p = sub.add_parser("detect", help="Publish pose.detect.requested.")
    p.add_argument("--job-id", required=True)
    p.add_argument("--object-key", required=True)
    p = sub.add_parser("advice", help="Publish pose.advice.requested (--job-id is the video id).")
    p.add_argument("--job-id", required=True)
    p = sub.add_parser("seed-route", help="Create a test user and route; upload the photo; print route_id and object_key.")
    p.add_argument("--image", required=True)
    p = sub.add_parser("holds", help="Publish holds.detect.requested (--job-id is the route id).")
    p.add_argument("--job-id", required=True)
    p.add_argument("--object-key", required=True)
    p = sub.add_parser("seed-pathfinding", help="Create a pending pathfinding on an existing route; print pathfinding_id.")
    p.add_argument("--route-id", required=True)
    p.add_argument("--height", type=float, default=175.0)
    p.add_argument("--arm-span", type=float, default=178.0)
    p = sub.add_parser("pathfinding", help="Publish pathfinding.compute.requested (--job-id is the pathfinding id).")
    p.add_argument("--job-id", required=True)
    p.add_argument("--preference", choices=[p.value for p in BetaPreference])
    return parser


def main(argv: list[str] | None = None) -> None:
    load_dotenv()
    args = build_parser().parse_args(argv)
    try:
        if args.command == "seed":
            seeded = seed(args.video)
            print(f"job_id={seeded.job_id}\nobject_key={seeded.object_key}\nvideo_id={seeded.video_id}")
        elif args.command == "detect":
            publish(RoutingKey.POSE_DETECT_REQUESTED, PoseDetectRequest(job_id=args.job_id, object_key=args.object_key))
        elif args.command == "seed-route":
            seeded = seed_route(args.image)
            print(f"route_id={seeded.route_id}\nobject_key={seeded.object_key}")
        elif args.command == "holds":
            publish(RoutingKey.HOLDS_DETECT_REQUESTED, HoldDetectRequest(job_id=args.job_id, object_key=args.object_key))
        elif args.command == "seed-pathfinding":
            seeded = seed_pathfinding(args.route_id, ClimberMorphology(height_cm=args.height, arm_span_cm=args.arm_span))
            print(f"pathfinding_id={seeded.pathfinding_id}")
        elif args.command == "pathfinding":
            preference = BetaPreference(args.preference) if args.preference else None
            publish(RoutingKey.PATHFINDING_COMPUTE_REQUESTED, PathfindingComputeRequest(job_id=args.job_id, preference=preference))
        else:
            publish(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id=args.job_id))
    except Exception as e:  # noqa: BLE001
        log.error("Producer failed: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
