BEGIN;

DROP INDEX IF EXISTS idx_analyses_status;
DROP INDEX IF EXISTS idx_analyses_video_created;

ALTER TABLE analyses
    DROP CONSTRAINT IF EXISTS chk_analyses_failed,
    DROP CONSTRAINT IF EXISTS chk_analyses_completed,
    DROP CONSTRAINT IF EXISTS chk_analyses_progress,
    DROP COLUMN IF EXISTS visibility,
    DROP COLUMN IF EXISTS started_at;

ALTER TABLE analyses
    ALTER COLUMN hints TYPE TEXT
    USING CASE WHEN hints IS NULL THEN NULL ELSE COALESCE(hints->>'summary', hints::TEXT) END;

ALTER TABLE analyses RENAME COLUMN processing_time_ms TO processing_time;
ALTER TABLE analyses ALTER COLUMN progress TYPE INTEGER;

ALTER TABLE analyses ALTER COLUMN status DROP DEFAULT;
ALTER TABLE analyses ALTER COLUMN status TYPE TEXT USING status::TEXT;
ALTER TABLE analyses ALTER COLUMN status SET DEFAULT 'pending';

-- Keep only the latest analysis per (video, type) so the old unique constraint fits again.
DELETE FROM analyses a
 USING analyses b
 WHERE a.video_id = b.video_id
   AND a.type = b.type
   AND a.created_at < b.created_at;

ALTER TABLE analyses
    ADD CONSTRAINT uq_analyses_video_id_type UNIQUE (video_id, type);

CREATE INDEX idx_analyses_video_id ON analyses(video_id);
CREATE INDEX idx_analyses_status ON analyses(status);
CREATE INDEX idx_analyses_video_id_type ON analyses(video_id, type);

COMMIT;
