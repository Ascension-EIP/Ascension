CREATE TYPE training_session_type AS ENUM ('technique', 'strength', 'endurance', 'climbing', 'recovery', 'rest');

CREATE TABLE training_program_sessions (
    id            UUID PRIMARY KEY DEFAULT uuidv7(),
    program_id    UUID NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    week_number   SMALLINT NOT NULL,
    day_of_week   SMALLINT NOT NULL,
    type          training_session_type NOT NULL,
    title         TEXT NOT NULL,
    description   TEXT,
    duration_min  SMALLINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_training_program_sessions_week CHECK (week_number >= 1),
    CONSTRAINT chk_training_program_sessions_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT uq_training_program_sessions_slot UNIQUE (program_id, week_number, day_of_week)
);

CREATE TRIGGER update_training_program_sessions_updated_at
    BEFORE UPDATE ON training_program_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
