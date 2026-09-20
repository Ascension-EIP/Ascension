CREATE TABLE comparisons (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    analysis_id         UUID NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
    ghost_id            UUID NOT NULL REFERENCES ghosts(id) ON DELETE CASCADE,
    status              job_status NOT NULL DEFAULT 'pending',
    progress            SMALLINT NOT NULL DEFAULT 0,
    similarity_score    NUMERIC(5, 2),
    efficiency_score    NUMERIC(5, 2),
    metrics             JSONB,
    error               TEXT,
    processing_time_ms  INTEGER,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_comparisons_progress CHECK (progress BETWEEN 0 AND 100),
    CONSTRAINT chk_comparisons_scores CHECK (
        (similarity_score IS NULL OR similarity_score BETWEEN 0 AND 100) AND
        (efficiency_score IS NULL OR efficiency_score BETWEEN 0 AND 100)
    ),
    CONSTRAINT chk_comparisons_completed
        CHECK (status <> 'completed' OR (metrics IS NOT NULL AND completed_at IS NOT NULL))
);

CREATE INDEX idx_comparisons_analysis_id ON comparisons(analysis_id);
CREATE INDEX idx_comparisons_ghost_id ON comparisons(ghost_id);

CREATE TRIGGER update_comparisons_updated_at
    BEFORE UPDATE ON comparisons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
