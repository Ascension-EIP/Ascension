CREATE TABLE goals (
    id                      UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id                 UUID NOT NULL,
    status                  goal_status NOT NULL DEFAULT 'active',
    current_grade           TEXT NOT NULL,
    target_grade            TEXT NOT NULL,
    grading_system          grading_system NOT NULL,
    focus_areas             focus_area[] NOT NULL DEFAULT '{}',
    training_days_per_week  SMALLINT NOT NULL,
    target_date             DATE NOT NULL,
    achieved_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_goals_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_goals_days CHECK (training_days_per_week BETWEEN 1 AND 7),
    CONSTRAINT chk_goals_achieved
        CHECK ((status = 'achieved') = (achieved_at IS NOT NULL))
);

CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE UNIQUE INDEX uq_goals_active ON goals(user_id) WHERE status = 'active';

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE training_programs (
    id                UUID PRIMARY KEY DEFAULT uuidv7(),
    goal_id           UUID NOT NULL,
    author_user_id    UUID,
    status            training_program_status NOT NULL DEFAULT 'draft',
    version           SMALLINT NOT NULL DEFAULT 1,
    title             TEXT NOT NULL,
    description       TEXT,
    duration_weeks    SMALLINT NOT NULL,
    starts_on         DATE,
    generation_input  JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_training_programs_goal_id
        FOREIGN KEY (goal_id)
        REFERENCES goals(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_training_programs_author_user_id
        FOREIGN KEY (author_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_training_programs_duration CHECK (duration_weeks BETWEEN 1 AND 52),
    CONSTRAINT uq_training_programs_goal_version UNIQUE (goal_id, version)
);

CREATE INDEX idx_training_programs_author_user_id ON training_programs(author_user_id);
CREATE UNIQUE INDEX uq_training_programs_active ON training_programs(goal_id) WHERE status = 'active';

CREATE TRIGGER update_training_programs_updated_at
    BEFORE UPDATE ON training_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE training_program_sessions (
    id            UUID PRIMARY KEY DEFAULT uuidv7(),
    program_id    UUID NOT NULL,
    week_number   SMALLINT NOT NULL,
    day_of_week   SMALLINT NOT NULL,
    type          training_session_type NOT NULL,
    title         TEXT NOT NULL,
    description   TEXT,
    duration_min  SMALLINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_training_program_sessions_program_id
        FOREIGN KEY (program_id)
        REFERENCES training_programs(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_training_program_sessions_week CHECK (week_number >= 1),
    CONSTRAINT chk_training_program_sessions_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT uq_training_program_sessions_slot UNIQUE (program_id, week_number, day_of_week)
);

CREATE TRIGGER update_training_program_sessions_updated_at
    BEFORE UPDATE ON training_program_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE exercises (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    program_session_id  UUID NOT NULL,
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

    CONSTRAINT fk_exercises_program_session_id
        FOREIGN KEY (program_session_id)
        REFERENCES training_program_sessions(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_exercises_position UNIQUE (program_session_id, position)
);

CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE training_logs (
    id                   UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id              UUID NOT NULL,
    program_session_id   UUID,
    climbing_session_id  UUID,
    type                 training_session_type NOT NULL,
    performed_on         DATE NOT NULL,
    duration_min         SMALLINT NOT NULL,
    perceived_effort     SMALLINT,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_training_logs_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_training_logs_program_session_id
        FOREIGN KEY (program_session_id)
        REFERENCES training_program_sessions(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_training_logs_climbing_session_id
        FOREIGN KEY (climbing_session_id)
        REFERENCES climbing_sessions(id)
        ON DELETE SET NULL,

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
