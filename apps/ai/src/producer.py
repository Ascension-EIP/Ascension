# @date 2026-11-01
# @file producer.py
# @brief Stand-in for the Go server: seeds a test analysis and publishes worker jobs.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Stand-in for the Go server, until it publishes on the worker queues.

Usage (from ``apps/ai``, or ``moon run ai:producer -- <args>``)::

    uv run python src/producer.py seed --video resources/example-2.mp4
    uv run python src/producer.py detect --job-id <id> --object-key <key>
    uv run python src/producer.py advice --job-id <id>

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
from shared.models import Job, PoseDetectRequest, RoutingKey


class Seeded(NamedTuple):
    job_id: str
    object_key: str
    user_id: str


def seed(video: str, db: PostgreSQL | None = None, storage: RustFS | None = None) -> Seeded:
    """Create a user, a video row and a `pending` analysis, and upload ``video``.

    The bucket is created if missing (the worker never does it), so this runs
    without the Go server. Everything is named after a unique suffix.
    """
    db = db or PostgreSQL().setup_config().connect()
    storage = storage or RustFS().setup_config()
    if storage.client is None:
        try:
            storage.connect()
        except PermanentError:
            # `connect` builds the client before checking the bucket, so it is usable here.
            storage.client.create_bucket(Bucket=storage.config.bucket)

    name = f"seed{uuid4().hex[:12]}"
    object_key = f"seed/{name}{Path(video).suffix}"
    storage.client.upload_file(video, storage.config.bucket, object_key)
    user = db.connection.execute(
        "INSERT INTO users (username, first_name, last_name, email, password_hash)"
        " VALUES (%s, 'Seed', 'Seed', %s, 'x') RETURNING id",
        (name, f"{name}@example.com"),
    ).fetchone()[0]
    video_id = db.connection.execute(
        "INSERT INTO videos (user_id, object_key, content_type) VALUES (%s, %s, 'video/mp4') RETURNING id",
        (user, object_key),
    ).fetchone()[0]
    job_id = db.connection.execute("INSERT INTO analyses (video_id) VALUES (%s) RETURNING id", (video_id,)).fetchone()[0]
    return Seeded(str(job_id), object_key, str(user))


def publish(routing_key: RoutingKey, payload: Job | PoseDetectRequest) -> None:
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
    p = sub.add_parser("advice", help="Publish pose.advice.requested.")
    p.add_argument("--job-id", required=True)
    return parser


def main(argv: list[str] | None = None) -> None:
    load_dotenv()
    args = build_parser().parse_args(argv)
    try:
        if args.command == "seed":
            seeded = seed(args.video)
            print(f"job_id={seeded.job_id}\nobject_key={seeded.object_key}")
        elif args.command == "detect":
            publish(RoutingKey.POSE_DETECT_REQUESTED, PoseDetectRequest(job_id=args.job_id, object_key=args.object_key))
        else:
            publish(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id=args.job_id))
    except Exception as e:  # noqa: BLE001
        log.error("Producer failed: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
