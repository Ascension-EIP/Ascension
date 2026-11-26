-- The pathfinding computes the beta (hold under each limb, step by step) and the postures of each step,
-- and stores them. The tables follow the computation:
-- ghosts -> pathfindings (path -> result, like analyses.result and advices.result),
-- ghost_holds -> pathfinding_holds, ghost_id -> pathfinding_id (also in comparisons).
-- quota_usages.ghosts_count and subscription_plans.*ghost* are the commercial Ghost Mode quota: unchanged.
BEGIN;

ALTER TABLE ghosts RENAME TO pathfindings;
ALTER TABLE pathfindings RENAME COLUMN path TO result;
ALTER TABLE ghost_holds RENAME TO pathfinding_holds;
ALTER TABLE pathfinding_holds RENAME COLUMN ghost_id TO pathfinding_id;
ALTER TABLE comparisons RENAME COLUMN ghost_id TO pathfinding_id;

ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_pkey TO pathfindings_pkey;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_route_id_fkey TO pathfindings_route_id_fkey;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_user_id_fkey TO pathfindings_user_id_fkey;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_ghosts_progress TO chk_pathfindings_progress;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_ghosts_completed TO chk_pathfindings_completed;
ALTER TABLE pathfindings RENAME CONSTRAINT chk_ghosts_failed TO chk_pathfindings_failed;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT ghost_holds_pkey TO pathfinding_holds_pkey;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT ghost_holds_ghost_id_fkey TO pathfinding_holds_pathfinding_id_fkey;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT ghost_holds_hold_id_fkey TO pathfinding_holds_hold_id_fkey;
ALTER TABLE comparisons RENAME CONSTRAINT comparisons_ghost_id_fkey TO comparisons_pathfinding_id_fkey;

-- PostgreSQL 18 names the NOT NULL constraints after the table and the column.
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_id_not_null TO pathfindings_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_route_id_not_null TO pathfindings_route_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_user_id_not_null TO pathfindings_user_id_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_status_not_null TO pathfindings_status_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_progress_not_null TO pathfindings_progress_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_morphology_not_null TO pathfindings_morphology_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_created_at_not_null TO pathfindings_created_at_not_null;
ALTER TABLE pathfindings RENAME CONSTRAINT ghosts_updated_at_not_null TO pathfindings_updated_at_not_null;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT ghost_holds_ghost_id_not_null TO pathfinding_holds_pathfinding_id_not_null;
ALTER TABLE pathfinding_holds RENAME CONSTRAINT ghost_holds_hold_id_not_null TO pathfinding_holds_hold_id_not_null;
ALTER TABLE comparisons RENAME CONSTRAINT comparisons_ghost_id_not_null TO comparisons_pathfinding_id_not_null;

ALTER INDEX idx_ghosts_route_created RENAME TO idx_pathfindings_route_created;
ALTER INDEX idx_ghosts_user_id RENAME TO idx_pathfindings_user_id;
ALTER INDEX idx_ghost_holds_hold_id RENAME TO idx_pathfinding_holds_hold_id;
ALTER INDEX idx_comparisons_ghost_id RENAME TO idx_comparisons_pathfinding_id;

ALTER TRIGGER update_ghosts_updated_at ON pathfindings RENAME TO update_pathfindings_updated_at;

COMMIT;
