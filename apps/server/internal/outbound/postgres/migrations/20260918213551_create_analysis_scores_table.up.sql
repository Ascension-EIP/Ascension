CREATE TABLE analysis_scores (
    analysis_id      UUID PRIMARY KEY REFERENCES analyses(id) ON DELETE CASCADE,
    overall_score    NUMERIC(5, 2) NOT NULL,
    technique_score  NUMERIC(5, 2) NOT NULL,
    power_score      NUMERIC(5, 2) NOT NULL,
    endurance_score  NUMERIC(5, 2) NOT NULL,
    details          JSONB,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_analysis_scores_range CHECK (
        overall_score   BETWEEN 0 AND 100 AND
        technique_score BETWEEN 0 AND 100 AND
        power_score     BETWEEN 0 AND 100 AND
        endurance_score BETWEEN 0 AND 100
    )
);
