-- Hold detection job (AI worker, queue holds.detect).
-- routes gets the same job columns as analyses and ghosts: the server creates the route in
-- `pending` and publishes holds.detect.requested, the worker writes the holds and the status.
-- holds gets the hold colour (current value and frozen prediction, like type and contour).
-- hold_type gets `unknown`: the detector finds holds and volumes but does not classify grips yet.
BEGIN;

ALTER TYPE hold_type ADD VALUE IF NOT EXISTS 'unknown';

ALTER TABLE routes
    ADD COLUMN status             job_status NOT NULL DEFAULT 'pending',
    ADD COLUMN progress           SMALLINT NOT NULL DEFAULT 0,
    ADD COLUMN error              TEXT,
    ADD COLUMN processing_time_ms INTEGER,
    ADD COLUMN started_at         TIMESTAMPTZ,
    ADD COLUMN completed_at       TIMESTAMPTZ,
    ADD CONSTRAINT chk_routes_progress CHECK (progress BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_routes_completed
        CHECK (status <> 'success' OR completed_at IS NOT NULL),
    ADD CONSTRAINT chk_routes_failed
        CHECK (status <> 'failed' OR error IS NOT NULL);

ALTER TABLE holds
    ADD COLUMN color           JSONB,
    ADD COLUMN predicted_color JSONB;

COMMIT;
