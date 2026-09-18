DROP TRIGGER IF EXISTS update_videos_updated_at ON videos;

DROP INDEX idx_videos_user_id;
DROP INDEX idx_videos_expires_at;

DROP TABLE IF EXISTS videos CASCADE;
