CREATE TABLE user_profiles (
    user_id            UUID PRIMARY KEY,
    birth_date         DATE,
    height_cm          SMALLINT,
    weight_kg          NUMERIC(5, 2),
    arm_span_cm        SMALLINT,
    dominant_hand      dominant_hand,
    climbing_level     TEXT,
    grading_system     grading_system,
    years_of_practice  SMALLINT,
    bio                TEXT,
    avatar_object_key  TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_profiles_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_user_profiles_height
        CHECK (height_cm IS NULL OR height_cm BETWEEN 50 AND 250),
    CONSTRAINT chk_user_profiles_weight
        CHECK (weight_kg IS NULL OR weight_kg BETWEEN 20 AND 250),
    CONSTRAINT chk_user_profiles_arm_span
        CHECK (arm_span_cm IS NULL OR arm_span_cm BETWEEN 50 AND 280),
    CONSTRAINT chk_user_profiles_level
        CHECK ((climbing_level IS NULL) = (grading_system IS NULL))
);

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Every user owns exactly one profile row, created empty at signup.
INSERT INTO user_profiles (user_id) SELECT id FROM users;

CREATE TABLE user_body_constraints (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID NOT NULL,
    zone        body_zone NOT NULL,
    type        body_constraint_type NOT NULL,
    note        TEXT,
    started_at  DATE NOT NULL DEFAULT CURRENT_DATE,
    ended_at    DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_body_constraints_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_user_body_constraints_dates
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE INDEX idx_user_body_constraints_user_id ON user_body_constraints(user_id);
CREATE UNIQUE INDEX uq_user_body_constraints_active
    ON user_body_constraints(user_id, zone)
    WHERE ended_at IS NULL;

CREATE TRIGGER update_user_body_constraints_updated_at
    BEFORE UPDATE ON user_body_constraints
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE tutorial_progress (
    user_id        UUID NOT NULL,
    tutorial_code  TEXT NOT NULL,
    status         tutorial_status NOT NULL DEFAULT 'not_started',
    current_step   SMALLINT NOT NULL DEFAULT 0,
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, tutorial_code),

    CONSTRAINT fk_tutorial_progress_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    -- One-way: a replayed tutorial keeps its first completion date.
    CONSTRAINT chk_tutorial_progress_completed
        CHECK (status <> 'completed' OR completed_at IS NOT NULL)
);

CREATE TRIGGER update_tutorial_progress_updated_at
    BEFORE UPDATE ON tutorial_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
