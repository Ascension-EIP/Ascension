DROP TABLE IF EXISTS sessions CASCADE;

DROP INDEX CONCURRENTLY idx_sessions_user_id;
DROP INDEX CONCURRENTLY idx_sessions_expires_at;
