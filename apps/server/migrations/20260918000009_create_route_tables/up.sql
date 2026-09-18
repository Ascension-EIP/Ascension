CREATE TABLE routes (
    id                UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id           UUID NOT NULL,
    gym_id            UUID,
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

    CONSTRAINT fk_routes_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_routes_gym_id
        FOREIGN KEY (gym_id)
        REFERENCES gyms(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_routes_grade
        CHECK ((grade IS NULL) = (grading_system IS NULL))
);

CREATE INDEX idx_routes_user_created ON routes(user_id, created_at DESC);
CREATE INDEX idx_routes_gym_id ON routes(gym_id);

CREATE TRIGGER update_routes_updated_at
    BEFORE UPDATE ON routes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE holds (
    id                    UUID PRIMARY KEY DEFAULT uuidv7(),
    route_id              UUID NOT NULL,
    source                hold_source NOT NULL,
    type                  hold_type NOT NULL,
    difficulty            SMALLINT,
    usable                BOOLEAN NOT NULL DEFAULT TRUE,
    contour               JSONB NOT NULL,
    predicted_type        hold_type,
    predicted_confidence  NUMERIC(4, 3),
    predicted_contour     JSONB,
    corrected_at          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_holds_route_id
        FOREIGN KEY (route_id)
        REFERENCES routes(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_holds_difficulty
        CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5),
    CONSTRAINT chk_holds_confidence
        CHECK (predicted_confidence IS NULL OR predicted_confidence BETWEEN 0 AND 1),
    CONSTRAINT chk_holds_prediction
        CHECK (source = 'manual' OR (predicted_type IS NOT NULL AND predicted_confidence IS NOT NULL))
);

CREATE INDEX idx_holds_route_id ON holds(route_id);
CREATE INDEX idx_holds_corrected ON holds(route_id) WHERE corrected_at IS NOT NULL;

CREATE TRIGGER update_holds_updated_at
    BEFORE UPDATE ON holds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE ghosts (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    route_id            UUID NOT NULL,
    user_id             UUID NOT NULL,
    status              job_status NOT NULL DEFAULT 'pending',
    progress            SMALLINT NOT NULL DEFAULT 0,
    morphology          JSONB NOT NULL,
    path                JSONB,
    error               TEXT,
    processing_time_ms  INTEGER,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_ghosts_route_id
        FOREIGN KEY (route_id)
        REFERENCES routes(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ghosts_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_ghosts_progress CHECK (progress BETWEEN 0 AND 100),
    CONSTRAINT chk_ghosts_completed
        CHECK (status <> 'completed' OR (path IS NOT NULL AND completed_at IS NOT NULL)),
    CONSTRAINT chk_ghosts_failed
        CHECK (status <> 'failed' OR error IS NOT NULL)
);

CREATE INDEX idx_ghosts_route_created ON ghosts(route_id, created_at DESC);
CREATE INDEX idx_ghosts_user_id ON ghosts(user_id);

CREATE TRIGGER update_ghosts_updated_at
    BEFORE UPDATE ON ghosts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE ghost_holds (
    ghost_id  UUID NOT NULL,
    hold_id   UUID NOT NULL,
    position  SMALLINT,

    PRIMARY KEY (ghost_id, hold_id),

    CONSTRAINT fk_ghost_holds_ghost_id
        FOREIGN KEY (ghost_id)
        REFERENCES ghosts(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ghost_holds_hold_id
        FOREIGN KEY (hold_id)
        REFERENCES holds(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_ghost_holds_hold_id ON ghost_holds(hold_id);

CREATE TABLE comparisons (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    analysis_id         UUID NOT NULL,
    ghost_id            UUID NOT NULL,
    status              job_status NOT NULL DEFAULT 'pending',
    progress            SMALLINT NOT NULL DEFAULT 0,
    similarity_score    NUMERIC(5, 2),
    efficiency_score    NUMERIC(5, 2),
    metrics             JSONB,
    error               TEXT,
    processing_time_ms  INTEGER,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_comparisons_analysis_id
        FOREIGN KEY (analysis_id)
        REFERENCES analyses(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comparisons_ghost_id
        FOREIGN KEY (ghost_id)
        REFERENCES ghosts(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_comparisons_progress CHECK (progress BETWEEN 0 AND 100),
    CONSTRAINT chk_comparisons_scores CHECK (
        (similarity_score IS NULL OR similarity_score BETWEEN 0 AND 100) AND
        (efficiency_score IS NULL OR efficiency_score BETWEEN 0 AND 100)
    ),
    CONSTRAINT chk_comparisons_completed
        CHECK (status <> 'completed' OR (metrics IS NOT NULL AND completed_at IS NOT NULL))
);

CREATE INDEX idx_comparisons_analysis_id ON comparisons(analysis_id);
CREATE INDEX idx_comparisons_ghost_id ON comparisons(ghost_id);

CREATE TRIGGER update_comparisons_updated_at
    BEFORE UPDATE ON comparisons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
