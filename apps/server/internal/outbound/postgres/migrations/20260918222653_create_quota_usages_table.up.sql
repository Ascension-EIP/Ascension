CREATE TABLE quota_usages (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period_start    DATE NOT NULL,
    analyses_count  INTEGER NOT NULL DEFAULT 0,
    ghosts_count    INTEGER NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, period_start),

    CONSTRAINT chk_quota_usages_period
        CHECK (period_start = DATE_TRUNC('month', period_start)::DATE),
    CONSTRAINT chk_quota_usages_counts
        CHECK (analyses_count >= 0 AND ghosts_count >= 0)
);

CREATE TRIGGER update_quota_usages_updated_at
    BEFORE UPDATE ON quota_usages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
