CREATE TYPE dominant_hand AS ENUM ('left', 'right', 'ambidextrous');
CREATE TYPE grading_system AS ENUM ('font', 'french', 'v_scale', 'yds');

CREATE TABLE user_profiles (
    user_id            UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
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
