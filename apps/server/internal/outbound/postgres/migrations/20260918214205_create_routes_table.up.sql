CREATE TABLE routes (
    id                UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gym_id            UUID REFERENCES gyms(id) ON DELETE SET NULL,
    name              TEXT,
    grade             TEXT,
    grading_system    grading_system,
    color             TEXT,
    image_object_key  TEXT NOT NULL UNIQUE,
    image_width       SMALLINT NOT NULL,
    image_height      SMALLINT NOT NULL,
    visibility        visibility NOT NULL DEFAULT 'private',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_routes_grade
        CHECK ((grade IS NULL) = (grading_system IS NULL))
);

CREATE INDEX idx_routes_user_created ON routes(user_id, created_at DESC);
CREATE INDEX idx_routes_gym_id ON routes(gym_id);

CREATE TRIGGER update_routes_updated_at
    BEFORE UPDATE ON routes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

