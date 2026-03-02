# Skill: RabbitMQ Worker Pattern

## When to use
Any Ascension AI worker that consumes jobs from a RabbitMQ queue, processes them, persists results, and publishes events.

## Pattern

```
main():
  1. Connect to RabbitMQ with retry loop (handle startup race)
  2. Declare durable queue + topic exchange (ascension.events)
  3. Set prefetch_count=1, start consuming

on_message(ch, method, props, body):
  1. Parse job JSON
  2. Download asset from MinIO/S3 (boto3) to tempfile
  3. Run processing (e.g. pose_analysis.analyze())
  4. UPDATE result in PostgreSQL (status, result_json, processing_time_ms, completed_at)
  5. Publish event to ascension.events exchange (routing key: {pipeline}.completed.{job_id})
  6. basic_ack
  On error:
  - basic_nack(requeue=True)
  - Best-effort DB update to status='failed'
  - Temp file cleanup in finally block
```

## Key conventions
- S3 URLs: `s3://bucket/key` — parse with `urlparse`
- Temp files: `tempfile.NamedTemporaryFile(delete=False)`, unlink in `finally`
- DB connections: open per-job, close in `finally`
- Logging: `logging` module, not `print()`
- Retry: 12 attempts × 5s for RabbitMQ connection

## Reference
- `apps/ai/consumer.py` — canonical implementation
