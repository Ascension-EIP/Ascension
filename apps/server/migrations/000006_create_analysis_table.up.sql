CREATE TABLE analysis (
	id UUID PRIMARY KEY DEFAULT uuidv7(),
	video_id UUID NOT NULL UNIQUE REFERENCES videos(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    result_json JSONB,
    processing_time_ms INTEGER,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
