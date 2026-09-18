BEGIN;

DROP INDEX IF EXISTS idx_videos_expiry;
DROP INDEX IF EXISTS idx_videos_climbing_session_id;
DROP INDEX IF EXISTS idx_videos_user_created;

ALTER TABLE videos
    DROP CONSTRAINT IF EXISTS fk_videos_climbing_session_id,
    DROP CONSTRAINT IF EXISTS videos_object_key_key,
    DROP COLUMN IF EXISTS visibility,
    DROP COLUMN IF EXISTS retained,
    DROP COLUMN IF EXISTS fps,
    DROP COLUMN IF EXISTS height,
    DROP COLUMN IF EXISTS width,
    DROP COLUMN IF EXISTS content_type,
    DROP COLUMN IF EXISTS title,
    DROP COLUMN IF EXISTS climbing_session_id;

ALTER TABLE videos ALTER COLUMN status DROP DEFAULT;
ALTER TABLE videos ALTER COLUMN status TYPE TEXT USING status::TEXT;
ALTER TABLE videos ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE videos ALTER COLUMN duration_ms TYPE BIGINT;
ALTER TABLE videos RENAME COLUMN duration_ms TO duration;
ALTER TABLE videos RENAME COLUMN size_bytes TO size;

-- The original bucket name is not stored anywhere else; restore the default one.
ALTER TABLE videos ADD COLUMN bucket TEXT NOT NULL DEFAULT 'videos';
ALTER TABLE videos ALTER COLUMN bucket DROP DEFAULT;

CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_videos_expires_at ON videos(expires_at);

COMMIT;
