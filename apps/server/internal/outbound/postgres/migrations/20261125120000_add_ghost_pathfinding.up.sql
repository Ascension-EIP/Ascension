-- Ghost pathfinding (AI worker, queue ghosts.compute).
-- holds gets the start and finish marks of the route: how many limbs start on (1 to 4) or must
-- finish on (1 to 2) the hold. NULL means the hold is not a start or finish hold.
-- routes gets feet_free (every usable hold of the photo can hold a foot) and the wall plane
-- estimated by the hold detection job (angle and homography photo pixels -> cm in the wall plane).
BEGIN;

ALTER TABLE holds
    ADD COLUMN start_limbs  SMALLINT,
    ADD COLUMN finish_limbs SMALLINT,
    ADD CONSTRAINT chk_holds_start_limbs
        CHECK (start_limbs IS NULL OR start_limbs BETWEEN 1 AND 4),
    ADD CONSTRAINT chk_holds_finish_limbs
        CHECK (finish_limbs IS NULL OR finish_limbs BETWEEN 1 AND 2);

ALTER TABLE routes
    ADD COLUMN feet_free      BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN wall_angle_deg NUMERIC(5, 2),
    ADD COLUMN wall_plane     JSONB,
    ADD CONSTRAINT chk_routes_wall_angle
        CHECK (wall_angle_deg IS NULL OR wall_angle_deg BETWEEN -90 AND 90);

COMMIT;
