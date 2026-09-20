CREATE TYPE analysis_type AS ENUM ('2d', '3d');
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'generating_hints', 'completed', 'failed');

CREATE TABLE analyses (
	id UUID PRIMARY KEY DEFAULT uuidv7(),
	video_id UUID NOT NULL UNIQUE REFERENCES videos(id) ON DELETE CASCADE,
	type analysis_type NOT NULL DEFAULT '2d',
    status job_status NOT NULL DEFAULT 'pending',
	visibility visibility NOT NULL DEFAULT 'private',
	progress SMALLINT NOT NULL DEFAULT 0,
    result JSONB,
	advice TEXT,
    error TEXT,
    processing_time_ms INTERVAL,
	started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_analyses_progress CHECK (progress BETWEEN 0 AND 100),
    CONSTRAINT chk_analyses_completed
        CHECK (status <> 'completed' OR (result IS NOT NULL AND completed_at IS NOT NULL)),
    CONSTRAINT chk_analyses_failed
        CHECK (status <> 'failed' OR error IS NOT NULL)
);

CREATE INDEX idx_analyses_video_created ON analyses(video_id, created_at DESC);
CREATE INDEX idx_analyses_status ON analyses(status)
    WHERE status IN ('pending', 'processing', 'generating_hints');

CREATE TRIGGER update_analyses_updated_at
	BEFORE UPDATE ON analyses
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
