CREATE TABLE ghosts (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    route_id            UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status              job_status NOT NULL DEFAULT 'pending',
    progress            SMALLINT NOT NULL DEFAULT 0,
    morphology          JSONB NOT NULL,
    path                JSONB,
    error               TEXT,
    processing_time_ms  INTEGER,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_ghosts_progress CHECK (progress BETWEEN 0 AND 100),
    CONSTRAINT chk_ghosts_completed
        CHECK (status <> 'completed' OR (path IS NOT NULL AND completed_at IS NOT NULL)),
    CONSTRAINT chk_ghosts_failed
        CHECK (status <> 'failed' OR error IS NOT NULL)
);

CREATE INDEX idx_ghosts_route_created ON ghosts(route_id, created_at DESC);
CREATE INDEX idx_ghosts_user_id ON ghosts(user_id);

CREATE TRIGGER update_ghosts_updated_at
    BEFORE UPDATE ON ghosts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
