CREATE TYPE hold_type AS ENUM ('jug', 'crimp', 'sloper', 'pinch', 'pocket', 'edge', 'volume', 'foothold');
CREATE TYPE hold_source AS ENUM ('ai', 'manual');

CREATE TABLE holds (
    id                    UUID PRIMARY KEY DEFAULT uuidv7(),
    route_id              UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
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


