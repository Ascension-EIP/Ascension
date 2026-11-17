-- Restore the previous job_status enum. started and running both become
-- processing (generating_hints is not restored).
BEGIN;

DROP INDEX idx_analyses_status;
ALTER TABLE analyses DROP CONSTRAINT chk_analyses_completed;
ALTER TABLE analyses DROP CONSTRAINT chk_analyses_failed;
ALTER TABLE ghosts DROP CONSTRAINT chk_ghosts_completed;
ALTER TABLE ghosts DROP CONSTRAINT chk_ghosts_failed;
ALTER TABLE comparisons DROP CONSTRAINT chk_comparisons_completed;

CREATE TYPE job_status_old AS ENUM ('pending', 'processing', 'generating_hints', 'completed', 'failed');

ALTER TABLE analyses ALTER COLUMN status DROP DEFAULT;
ALTER TABLE analyses ALTER COLUMN status TYPE job_status_old USING (
    CASE status::text
        WHEN 'started' THEN 'processing'
        WHEN 'running' THEN 'processing'
        WHEN 'success' THEN 'completed'
        ELSE status::text
    END
)::job_status_old;
ALTER TABLE analyses ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE ghosts ALTER COLUMN status DROP DEFAULT;
ALTER TABLE ghosts ALTER COLUMN status TYPE job_status_old USING (
    CASE status::text
        WHEN 'started' THEN 'processing'
        WHEN 'running' THEN 'processing'
        WHEN 'success' THEN 'completed'
        ELSE status::text
    END
)::job_status_old;
ALTER TABLE ghosts ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE comparisons ALTER COLUMN status DROP DEFAULT;
ALTER TABLE comparisons ALTER COLUMN status TYPE job_status_old USING (
    CASE status::text
        WHEN 'started' THEN 'processing'
        WHEN 'running' THEN 'processing'
        WHEN 'success' THEN 'completed'
        ELSE status::text
    END
)::job_status_old;
ALTER TABLE comparisons ALTER COLUMN status SET DEFAULT 'pending';

DROP TYPE job_status;
ALTER TYPE job_status_old RENAME TO job_status;

ALTER TABLE analyses ADD CONSTRAINT chk_analyses_completed
    CHECK (status <> 'completed' OR (result IS NOT NULL AND completed_at IS NOT NULL));
ALTER TABLE analyses ADD CONSTRAINT chk_analyses_failed
    CHECK (status <> 'failed' OR error IS NOT NULL);
ALTER TABLE ghosts ADD CONSTRAINT chk_ghosts_completed
    CHECK (status <> 'completed' OR (path IS NOT NULL AND completed_at IS NOT NULL));
ALTER TABLE ghosts ADD CONSTRAINT chk_ghosts_failed
    CHECK (status <> 'failed' OR error IS NOT NULL);
ALTER TABLE comparisons ADD CONSTRAINT chk_comparisons_completed
    CHECK (status <> 'completed' OR (metrics IS NOT NULL AND completed_at IS NOT NULL));

CREATE INDEX idx_analyses_status ON analyses(status)
    WHERE status IN ('pending', 'processing', 'generating_hints');

COMMIT;
