# @date 2026-09-18
# @file __init__.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os  # noqa: F401
import sys  # noqa: F401
import traceback

from dotenv import load_dotenv

from common.utils.logger import log
from services.minio import MinIO
from services.postgresql import PostgreSQL
from services.rabbitmq import Broker
from worker._1_mediapipe.pose_skeleton import PoseSkeleton

load_dotenv()

pose_skeleton = PoseSkeleton()
broker = Broker()
db = PostgreSQL()
storage = MinIO()


def main() -> None:
    try:
        load_dotenv()

        # start_consuming() est bloquant : il doit être appelé en dernier.
        broker.setup_config().connect().setup_channel().start_consuming()
        db.connect()
        storage.connect()
    except Exception:  # noqa: BLE001
        log.error(traceback.format_exc())

    # if args = aucun
    # try:
    #     result = VideoBodySkeleton(
    #         video_path="resources/example-2.mp4",
    #         model="resources/pose_landmarker_full.task",
    #     )
    #     result.render_video()
    # except Exception:
    # log.error(traceback.format_exc())
