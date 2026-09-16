# @date 2026-09-17
# @file __init__.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
import sys
import traceback

from dotenv import load_dotenv

from common.utils.logger import log
from services.minio import MinIO
from services.postgresql import PostgreSQL
from services.rabbitmq import Broker

load_dotenv()


def main() -> None:
    try:
        load_dotenv()
        db = PostgreSQL().connect()
        storage = MinIO().connect()
        # start_consuming() est bloquant : il doit être appelé en dernier.
        Broker().setup_config().connect().setup_channel().start_consuming()
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
