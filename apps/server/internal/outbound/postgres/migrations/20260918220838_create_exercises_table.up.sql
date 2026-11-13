CREATE TABLE exercises (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    program_session_id  UUID NOT NULL REFERENCES training_program_sessions(id) ON DELETE CASCADE,
    position            SMALLINT NOT NULL,
    name                TEXT NOT NULL,
    description         TEXT,
    sets                SMALLINT,
    reps                SMALLINT,
    duration_s          INTEGER,
    rest_s              INTEGER,
    target_grade        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_exercises_position UNIQUE (program_session_id, position)
);

CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
