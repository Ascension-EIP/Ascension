CREATE TABLE training_logs (
    id                   UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_session_id   UUID REFERENCES training_program_sessions(id) ON DELETE SET NULL,
    climbing_session_id  UUID REFERENCES climbing_sessions(id) ON DELETE SET NULL,
    type                 training_session_type NOT NULL,
    performed_on         DATE NOT NULL,
    duration_min         SMALLINT NOT NULL,
    perceived_effort     SMALLINT,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_training_logs_effort
        CHECK (perceived_effort IS NULL OR perceived_effort BETWEEN 1 AND 10)
);

CREATE INDEX idx_training_logs_user_performed ON training_logs(user_id, performed_on DESC);
CREATE INDEX idx_training_logs_program_session_id ON training_logs(program_session_id);
CREATE INDEX idx_training_logs_climbing_session_id ON training_logs(climbing_session_id);

CREATE TRIGGER update_training_logs_updated_at
    BEFORE UPDATE ON training_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
