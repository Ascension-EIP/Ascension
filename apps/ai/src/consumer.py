"""Ascension AI Worker — vision.skeleton pipeline.

Consumes jobs from the ``vision.skeleton`` RabbitMQ queue, downloads the
climbing video from MinIO/S3, runs MediaPipe pose analysis, persists
results in PostgreSQL and publishes a completion event.
"""

import json
import logging
import os
import tempfile
import time
from datetime import datetime, timezone
from urllib.parse import urlparse

import boto3
import pika
import psycopg2
from dotenv import load_dotenv

from apps.ai.src.pose_analysis import analyze

# Load .env from project root (two levels up from apps/ai/) so that
# RABBITMQ_HOST, MINIO_ENDPOINT, DB_URI etc. are available when the
# worker is launched locally with `moon run ai:dev`.
_HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_HERE, "..", "..", ".env"), override=False)

# ─── Logging ─────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("ai-worker")

# ─── Constants ───────────────────────────────────────────────────
QUEUE = "vision.skeleton"
EXCHANGE = "ascension.events"
RABBITMQ_RETRY_DELAY: int = 5  # seconds between connection attempts
RABBITMQ_MAX_RETRIES = 12  # ~60 s total before giving up


# ─── Clients ─────────────────────────────────────────────────────
def _s3_client():
    """Build a boto3 S3 client pointing at MinIO."""
    endpoint = os.getenv("MINIO_ENDPOINT")
    if not endpoint:
        host = os.getenv("MINIO_HOST", "minio")
        port = os.getenv("MINIO_PORT", "9000")
        endpoint = f"http://{host}:{port}"
    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=os.getenv("MINIO_ROOT_USER", "ascension"),
        aws_secret_access_key=os.getenv("MINIO_ROOT_PASSWORD", "ascension"),
        region_name="us-east-1",
    )


def _pg_conn():
    """Return a psycopg2 connection using DB_URI or individual vars."""
    uri = os.getenv("DB_URI")
    if uri:
        return psycopg2.connect(uri)
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "postgresql"),
        port=int(os.getenv("POSTGRES_PORT", "5432")),
        user=os.getenv("POSTGRES_USER", "ascension"),
        password=os.getenv("POSTGRES_PASSWORD", "ascension"),
        dbname=os.getenv("POSTGRES_DB", "ascension"),
    )


# ─── Helpers ─────────────────────────────────────────────────────
def _parse_s3_url(url: str) -> tuple[str, str]:
    """Parse ``s3://bucket/key`` into (bucket, key)."""
    parsed = urlparse(url)
    if parsed.scheme != "s3":
        raise ValueError(f"Expected s3:// URL, got: {url}")
    bucket = parsed.netloc
    key = parsed.path.lstrip("/")
    return bucket, key


def _download_video(s3, bucket: str, key: str) -> str:
    """Download an S3 object to a temporary file and return its path."""
    suffix = os.path.splitext(key)[1] or ".mp4"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    try:
        logger.info("Downloading s3://%s/%s → %s", bucket, key, tmp.name)
        s3.download_fileobj(bucket, key, tmp)
        tmp.close()
        return tmp.name
    except Exception:
        tmp.close()
        os.unlink(tmp.name)
        raise


def _update_analysis(
    conn,
    analysis_id: str,
    status: str,
    result_json=None,
    processing_time_ms: int | None = None,
):
    """Update the analyses row in PostgreSQL."""
    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE analyses
               SET status            = %s,
                   result_json       = %s,
                   processing_time_ms = %s,
                   completed_at      = %s
             WHERE id = %s
            """,
            (
                status,
                json.dumps(result_json) if result_json is not None else None,
                processing_time_ms,
                datetime.now(timezone.utc),
                analysis_id,
            ),
        )
    conn.commit()


def _publish_event(channel, job_id: str, payload: dict):
    """Publish a completion event on the ascension.events exchange."""
    routing_key = f"skeleton.completed.{job_id}"
    channel.basic_publish(
        exchange=EXCHANGE,
        routing_key=routing_key,
        body=json.dumps(payload),
        properties=pika.BasicProperties(
            content_type="application/json",
            delivery_mode=2,
        ),
    )
    logger.info("Published event %s", routing_key)


# ─── Message handler ─────────────────────────────────────────────
def on_message(ch, method, _properties, body):
    """Process a single vision.skeleton job."""
    job = json.loads(body)
    job_id = job.get("job_id", "unknown")
    analysis_id = job.get("analysis_id")
    video_url = job.get("video_url")
    logger.info("Received job %s (analysis=%s)", job_id, analysis_id)

    tmp_path = None
    conn = None
    try:
        # 1. Download video from MinIO/S3
        s3 = _s3_client()
        bucket, key = _parse_s3_url(video_url)
        tmp_path = _download_video(s3, bucket, key)

        # 2. Run MediaPipe analysis
        t0 = time.monotonic()
        result = analyze(tmp_path)
        processing_ms = int((time.monotonic() - t0) * 1000)
        logger.info(
            "Analysis done in %d ms (%d frames)",
            processing_ms,
            len(result.get("frames", [])),
        )

        # 3. Save results to PostgreSQL
        conn = _pg_conn()
        _update_analysis(conn, analysis_id, "completed", result, processing_ms)
        logger.info("Saved results for analysis %s", analysis_id)

        # 4. Publish completion event
        _publish_event(
            ch,
            job_id,
            {
                "job_id": job_id,
                "analysis_id": analysis_id,
                "status": "completed",
                "processing_time_ms": processing_ms,
            },
        )

        # 5. Ack
        ch.basic_ack(delivery_tag=method.delivery_tag)

    except Exception:
        logger.exception("Job %s failed", job_id)
        # Update DB status to 'failed' (best-effort)
        try:
            if conn is None:
                conn = _pg_conn()
            _update_analysis(conn, analysis_id, "failed")
        except Exception:
            logger.exception(
                "Could not update analysis %s to failed", analysis_id
            )
        # Discard the message — it is already marked `failed` in the DB.
        # Re-queuing would cause an infinite crash loop.
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        if conn:
            conn.close()


# ─── Entry point ─────────────────────────────────────────────────
def _connect(params: pika.ConnectionParameters) -> pika.BlockingConnection:
    """Try to connect to RabbitMQ, retrying on failure."""
    for attempt in range(1, RABBITMQ_MAX_RETRIES + 1):
        try:
            return pika.BlockingConnection(params)
        except pika.exceptions.AMQPConnectionError:
            logger.warning(
                "RabbitMQ not ready (attempt %d/%d), retrying in %ds…",
                attempt,
                RABBITMQ_MAX_RETRIES,
                RABBITMQ_RETRY_DELAY,
            )
            time.sleep(RABBITMQ_RETRY_DELAY)
    logger.critical(
        "Could not connect to RabbitMQ after %d attempts", RABBITMQ_MAX_RETRIES
    )
    raise SystemExit(1)


def main():
    """Connect to RabbitMQ with retries and start consuming.
    Automatically reconnects if the broker drops the connection."""
    params = pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
        port=int(os.getenv("RABBITMQ_PORT", "5672")),
        credentials=pika.PlainCredentials(
            os.getenv("RABBITMQ_DEFAULT_USER", "ascension"),
            os.getenv("RABBITMQ_DEFAULT_PASS", "ascension"),
        ),
        heartbeat=60,
        blocked_connection_timeout=300,
    )

    while True:
        try:
            connection = _connect(params)
            channel = connection.channel()

            # Declare durable queue (survives RabbitMQ restarts)
            channel.queue_declare(queue=QUEUE, durable=True)

            # Declare topic exchange for publishing events
            channel.exchange_declare(
                exchange=EXCHANGE, exchange_type="topic", durable=True
            )

            # One job at a time per worker
            channel.basic_qos(prefetch_count=1)

            channel.basic_consume(
                queue=QUEUE,
                on_message_callback=on_message,
                auto_ack=False,
            )

            logger.info("Worker ready — consuming from %s", QUEUE)
            channel.start_consuming()

        except (
            pika.exceptions.ConnectionClosedByBroker,
            pika.exceptions.AMQPChannelError,
            pika.exceptions.AMQPConnectionError,
        ) as exc:
            logger.warning(
                "RabbitMQ connection lost (%s), reconnecting in %ds…",
                exc,
                RABBITMQ_RETRY_DELAY,
            )
            time.sleep(RABBITMQ_RETRY_DELAY)
            continue
        except KeyboardInterrupt:
            logger.info("Worker stopped by user.")
            break


if __name__ == "__main__":
    print("Starting Ascension AI Worker…")
    logger.info("Starting AI worker…")
    logger.info(
        "Environment:\n%s",
        "\n".join(f"  {k}={v}" for k, v in sorted(os.environ.items())),
    )
    main()
