-- Undo 20261125120000_add_ghost_pathfinding.
BEGIN;

ALTER TABLE routes
    DROP CONSTRAINT chk_routes_wall_angle,
    DROP COLUMN wall_plane,
    DROP COLUMN wall_angle_deg,
    DROP COLUMN feet_free;

ALTER TABLE holds
    DROP CONSTRAINT chk_holds_finish_limbs,
    DROP CONSTRAINT chk_holds_start_limbs,
    DROP COLUMN finish_limbs,
    DROP COLUMN start_limbs;

COMMIT;
