BEGIN;

-- Several analyses per video are now allowed (re-runs after a failure, 2D then 3D).
ALTER TABLE analyses DROP CONSTRAINT IF EXISTS uq_analyses_video_id_type;
DROP INDEX IF EXISTS idx_analyses_video_id;
DROP INDEX IF EXISTS idx_analyses_status;
DROP INDEX IF EXISTS idx_analyses_video_id_type;

ALTER TABLE analyses ALTER COLUMN status DROP DEFAULT;
ALTER TABLE analyses ALTER COLUMN status TYPE job_status USING status::job_status;
ALTER TABLE analyses ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE analyses ALTER COLUMN progress TYPE SMALLINT;
ALTER TABLE analyses RENAME COLUMN processing_time TO processing_time_ms;

-- Free-text advice becomes structured JSON; existing text is kept as the summary.
ALTER TABLE analyses
    ALTER COLUMN hints TYPE JSONB
    USING CASE
        WHEN hints IS NULL THEN NULL
        ELSE jsonb_build_object('summary', hints, 'items', '[]'::jsonb)
    END;

ALTER TABLE analyses
    ADD COLUMN started_at TIMESTAMPTZ,
    ADD COLUMN visibility visibility NOT NULL DEFAULT 'private';

-- Bring existing rows in line with the lifecycle constraints below.
UPDATE analyses SET error = 'Unknown error' WHERE status = 'failed' AND error IS NULL;
UPDATE analyses SET status = 'failed', error = 'Completed without result'
 WHERE status = 'completed' AND (result IS NULL OR completed_at IS NULL);

ALTER TABLE analyses
    ADD CONSTRAINT chk_analyses_progress CHECK (progress BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_analyses_completed
        CHECK (status <> 'completed' OR (result IS NOT NULL AND completed_at IS NOT NULL)),
    ADD CONSTRAINT chk_analyses_failed
        CHECK (status <> 'failed' OR error IS NOT NULL);

CREATE INDEX idx_analyses_video_created ON analyses(video_id, created_at DESC);
CREATE INDEX idx_analyses_status ON analyses(status)
    WHERE status IN ('pending', 'processing', 'generating_hints');

COMMIT;
