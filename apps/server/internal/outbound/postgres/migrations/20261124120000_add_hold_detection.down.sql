-- Undo 20261124120000_add_hold_detection.
-- PostgreSQL cannot remove an enum value, so hold_type is recreated without `unknown`.
-- Holds still typed `unknown` were produced by the detector: they are deleted, and running
-- the detection again recreates them.
BEGIN;

ALTER TABLE holds
    DROP COLUMN predicted_color,
    DROP COLUMN color;

ALTER TABLE routes
    DROP CONSTRAINT chk_routes_failed,
    DROP CONSTRAINT chk_routes_completed,
    DROP CONSTRAINT chk_routes_progress,
    DROP COLUMN completed_at,
    DROP COLUMN started_at,
    DROP COLUMN processing_time_ms,
    DROP COLUMN error,
    DROP COLUMN progress,
    DROP COLUMN status;

DELETE FROM holds WHERE type = 'unknown' OR predicted_type = 'unknown';

ALTER TABLE holds DROP CONSTRAINT chk_holds_prediction;

CREATE TYPE hold_type_old AS ENUM ('jug', 'crimp', 'sloper', 'pinch', 'pocket', 'edge', 'volume', 'foothold');
ALTER TABLE holds ALTER COLUMN type TYPE hold_type_old USING type::text::hold_type_old;
ALTER TABLE holds ALTER COLUMN predicted_type TYPE hold_type_old USING predicted_type::text::hold_type_old;
DROP TYPE hold_type;
ALTER TYPE hold_type_old RENAME TO hold_type;

ALTER TABLE holds ADD CONSTRAINT chk_holds_prediction
    CHECK (source = 'manual' OR (predicted_type IS NOT NULL AND predicted_confidence IS NOT NULL));

COMMIT;
