# @date 2026-09-10
# @file __init__.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import sys

from dotenv import load_dotenv

from services.minio import MinIO
from services.postgresql import PostgreSQL
from services.rabbitmq import Broker

load_dotenv()


def main() -> None:
    broker = Broker()
    broker.connect()
    db = PostgreSQL()
    db.connect()
    storage = MinIO()
    storage.connect()

    # if args = aucun
    # try:
    #     result = VideoBodySkeleton(
    #         video_path="resources/example-2.mp4",
    #         model="resources/pose_landmarker_full.task",
    #     )
    #     result.render_video()
    # except Exception:
    # log.error(traceback.format_exc())
    sys.exit(0)
