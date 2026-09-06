# @date 2026-09-06
# @file coordinator.py
# @brief Job coordinator orchestrating storage, AI pipelines, database, and messaging.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Job coordinator connecting backend infrastructure to AI pipelines."""

import json
import logging
import os
import time
from typing import Any

from pika.adapters.blocking_connection import BlockingChannel

from src.config.settings import Settings
from src.core.interfaces import AdviceCapability
from src.core.models import CompletionEvent, JobPayload
from src.infrastructure.database import AnalysisRepository
from src.infrastructure.messaging import RabbitMQClient
from src.infrastructure.storage import StorageService
from src.pipelines.registry import PipelineRegistry

logger = logging.getLogger("ai-worker.coordinator")


class JobCoordinator:
    """Orchestrates the entire lifecycle of an analysis job."""

    def __init__(
        self,
        settings: Settings,
        storage: StorageService,
        db_repo: AnalysisRepository,
        messaging: RabbitMQClient,
    ):
        self.settings = settings
        self.storage = storage
        self.db_repo = db_repo
        self.messaging = messaging

    def handle_message(
        self,
        channel: BlockingChannel,
        method: Any,
        _properties: Any,
        body: bytes,
    ) -> None:
        """Process an incoming RabbitMQ job message."""
        try:
            data = json.loads(body)
            job = JobPayload.from_dict(data)
        except Exception as e:
            logger.error("Failed to parse incoming job JSON: %s (payload: %r)", e, body)
            channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            return

        logger.info("Received job %s (analysis=%s)", job.job_id, job.analysis_id)

        tmp_video_path = None
        db_conn = None

        try:
            # 1. Download video from S3/MinIO
            tmp_video_path = self.storage.download_video(job.video_url)

            # 2. Open DB connection for real-time progress
            db_conn = self.db_repo.get_connection()

            def on_progress(pct: int) -> None:
                self.db_repo.update_progress(db_conn, job.analysis_id, pct)
                logger.debug("Progress %d%% for analysis %s", pct, job.analysis_id)

            # 3. Select and execute requested AI pipeline
            pipeline_name = job.pipeline_name or self.settings.ai.active_pose_pipeline
            pipeline = PipelineRegistry.get(pipeline_name)
            logger.info("Executing pipeline '%s' for analysis %s", pipeline.name, job.analysis_id)

            t0 = time.monotonic()
            analysis_result = pipeline.analyze(tmp_video_path, on_progress=on_progress)
            processing_ms = int((time.monotonic() - t0) * 1000)

            # 4. Generate coaching advice if the pipeline supports it
            hints: str | None = None
            if isinstance(pipeline, AdviceCapability) and self.settings.ai.gemini_api_key:
                self.db_repo.update_status(db_conn, job.analysis_id, "generating_hints")
                logger.info("Requesting coaching advice for analysis %s", job.analysis_id)
                try:
                    hints = pipeline.generate_advice(analysis_result)
                    logger.info(
                        "Coaching advice generated (%d chars)",
                        len(hints) if hints else 0,
                    )
                except Exception as advice_err:
                    logger.warning(
                        "Advice generation failed for analysis %s: %s",
                        job.analysis_id,
                        advice_err,
                    )
                    hints = None

            # 5. Persist completed results into PostgreSQL
            self.db_repo.save_completed(
                conn=db_conn,
                analysis_id=job.analysis_id,
                result=analysis_result,
                processing_time=processing_ms,
                hints=hints,
            )

            # 6. Publish completion event to RabbitMQ topic exchange
            event = CompletionEvent(
                job_id=job.job_id,
                analysis_id=job.analysis_id,
                status="completed",
                processing_time_ms=processing_ms,
            )
            routing_key = f"skeleton.completed.{job.job_id}"
            self.messaging.publish_event(channel, routing_key, event.to_dict())

            # 7. Acknowledge message
            channel.basic_ack(delivery_tag=method.delivery_tag)
            logger.info("Successfully finished job %s in %d ms", job.job_id, processing_ms)

        except Exception as err:
            logger.exception("Job %s failed: %s", job.job_id, err)
            try:
                if db_conn is None:
                    db_conn = self.db_repo.get_connection()
                self.db_repo.mark_failed(db_conn, job.analysis_id, error=str(err))
            except Exception as db_err:
                logger.error("Failed to mark analysis %s as failed: %s", job.analysis_id, db_err)

            channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

        finally:
            if tmp_video_path and os.path.exists(tmp_video_path):
                try:
                    os.unlink(tmp_video_path)
                except OSError:
                    pass
            if db_conn is not None:
                try:
                    db_conn.close()
                except Exception:
                    pass
