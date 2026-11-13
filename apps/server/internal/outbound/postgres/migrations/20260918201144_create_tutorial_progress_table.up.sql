CREATE TYPE tutorial_status AS ENUM ('not_started', 'in_progress', 'completed');

CREATE TABLE tutorial_progress (
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tutorial_code  TEXT NOT NULL,
    status         tutorial_status NOT NULL DEFAULT 'not_started',
    current_step   SMALLINT NOT NULL DEFAULT 0,
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, tutorial_code),

    -- One-way: a replayed tutorial keeps its first completion date.
    CONSTRAINT chk_tutorial_progress_completed
        CHECK (status <> 'completed' OR completed_at IS NOT NULL)
);

CREATE TRIGGER update_tutorial_progress_updated_at
    BEFORE UPDATE ON tutorial_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
