CREATE TABLE analyses (
	id UUID PRIMARY KEY DEFAULT uuidv7(),
	video_id UUID NOT NULL UNIQUE REFERENCES videos(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    result_json JSONB,
	advice TEXT,
	progress INTEGER NOT NULL DEFAULT 0,
    processing_time_ms INTEGER,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_analyses_progress CHECK (progress BETWEEN 0 AND 100)
);

CREATE TRIGGER update_analyses_updated_at
	BEFORE UPDATE ON analyses
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
