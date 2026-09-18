CREATE TABLE gyms (
    id             UUID PRIMARY KEY DEFAULT uuidv7(),
    owner_user_id  UUID,
    name           TEXT NOT NULL,
    city           TEXT NOT NULL,
    country_code   CHAR(2) NOT NULL,
    address        TEXT,
    latitude       NUMERIC(9, 6),
    longitude      NUMERIC(9, 6),
    website_url    TEXT,
    is_partner     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_gyms_owner_user_id
        FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_gyms_city ON gyms(country_code, city);
CREATE INDEX idx_gyms_owner_user_id ON gyms(owner_user_id);

CREATE TRIGGER update_gyms_updated_at
    BEFORE UPDATE ON gyms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE climbing_sessions (
    id               UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id          UUID NOT NULL,
    gym_id           UUID,
    title            TEXT,
    started_at       TIMESTAMPTZ NOT NULL,
    ended_at         TIMESTAMPTZ,
    overall_score    NUMERIC(5, 2),
    technique_score  NUMERIC(5, 2),
    power_score      NUMERIC(5, 2),
    endurance_score  NUMERIC(5, 2),
    scored_at        TIMESTAMPTZ,
    notes            TEXT,
    visibility       visibility NOT NULL DEFAULT 'private',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_climbing_sessions_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_climbing_sessions_gym_id
        FOREIGN KEY (gym_id)
        REFERENCES gyms(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_climbing_sessions_dates
        CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT chk_climbing_sessions_scores CHECK (
        (overall_score   IS NULL OR overall_score   BETWEEN 0 AND 100) AND
        (technique_score IS NULL OR technique_score BETWEEN 0 AND 100) AND
        (power_score     IS NULL OR power_score     BETWEEN 0 AND 100) AND
        (endurance_score IS NULL OR endurance_score BETWEEN 0 AND 100)
    )
);

CREATE INDEX idx_climbing_sessions_user_started ON climbing_sessions(user_id, started_at DESC);
CREATE INDEX idx_climbing_sessions_gym_id ON climbing_sessions(gym_id);

CREATE TRIGGER update_climbing_sessions_updated_at
    BEFORE UPDATE ON climbing_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
