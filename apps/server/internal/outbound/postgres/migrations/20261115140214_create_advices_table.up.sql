CREATE TABLE advices (
	id UUID PRIMARY KEY REFERENCES videos(id) ON DELETE CASCADE,
	status job_status NOT NULL DEFAULT 'pending',
	progress SMALLINT NOT NULL DEFAULT 0,
	result JSONB,
	error TEXT,
	processing_time_ms INTERVAL,
	started_at TIMESTAMPTZ,
	completed_at TIMESTAMPTZ,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

	CONSTRAINT chk_advices_progress CHECK (progress BETWEEN 0 AND 100),
	CONSTRAINT chk_advices_completed
		CHECK (status <> 'success' OR (result IS NOT NULL AND completed_at IS NOT NULL)),
	CONSTRAINT chk_advices_failed
		CHECK (status <> 'failed' OR error IS NOT NULL)
);

CREATE INDEX idx_advices_status ON advices(status)
	WHERE status IN ('pending', 'started', 'running');

CREATE TRIGGER update_advices_updated_at
	BEFORE UPDATE ON advices
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
