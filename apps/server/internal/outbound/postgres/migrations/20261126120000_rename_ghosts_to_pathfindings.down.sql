-- Undo 20261126120000_rename_ghosts_to_pathfindings.
BEGIN;

ALTER TRIGGER update_pathfindings_updated_at ON pathfindings RENAME TO update_ghosts_updated_at;

ALTER INDEX idx_comparisons_pathfinding_id RENAME TO idx_comparisons_ghost_id;
ALTER INDEX idx_pathfinding_holds_hold_id RENAME TO idx_ghost_holds_hold_id;
ALTER INDEX idx_pathfindings_user_id RENAME TO idx_ghosts_user_id;
ALTER INDEX idx_pathfindings_route_created RENAME TO idx_ghosts_route_created;

ALTER TABLE comparisons RENAME CONSTRAINT comparisons_pathfinding_id_fkey TO comparisons_ghost_id_fkey;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT pathfinding_holds_hold_id_fkey TO ghost_holds_hold_id_fkey;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT pathfinding_holds_pathfinding_id_fkey TO ghost_holds_ghost_id_fkey;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT pathfinding_holds_pkey TO ghost_holds_pkey;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_pathfindings_failed TO chk_ghosts_failed;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_pathfindings_completed TO chk_ghosts_completed;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_pathfindings_progress TO chk_ghosts_progress;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_user_id_fkey TO ghosts_user_id_fkey;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_route_id_fkey TO ghosts_route_id_fkey;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_pkey TO ghosts_pkey;

-- PostgreSQL 18 names the NOT NULL constraints after the table and the column.
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_id_not_null TO ghosts_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_route_id_not_null TO ghosts_route_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_user_id_not_null TO ghosts_user_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_status_not_null TO ghosts_status_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_progress_not_null TO ghosts_progress_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_morphology_not_null TO ghosts_morphology_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_created_at_not_null TO ghosts_created_at_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT pathfindings_updated_at_not_null TO ghosts_updated_at_not_null;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT pathfinding_holds_pathfinding_id_not_null TO ghost_holds_ghost_id_not_null;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT pathfinding_holds_hold_id_not_null TO ghost_holds_hold_id_not_null;
ALTER TABLE comparisons RENAME CONSTRAINT comparisons_pathfinding_id_not_null TO comparisons_ghost_id_not_null;

ALTER TABLE comparisons RENAME COLUMN pathfinding_id TO ghost_id;
ALTER TABLE pathfinding_holds RENAME COLUMN pathfinding_id TO ghost_id;
ALTER TABLE pathfinding_holds RENAME TO ghost_holds;
ALTER TABLE pathfindings RENAME COLUMN result TO path;
ALTER TABLE pathfindings RENAME TO ghosts;

COMMIT;
