BEGIN;

DROP INDEX IF EXISTS idx_videos_user_id;
DROP INDEX IF EXISTS idx_videos_status;
DROP INDEX IF EXISTS idx_videos_expires_at;

-- The bucket is a server setting, not per-row data.
ALTER TABLE videos DROP COLUMN bucket;

ALTER TABLE videos RENAME COLUMN size TO size_bytes;
ALTER TABLE videos RENAME COLUMN duration TO duration_ms;
ALTER TABLE videos ALTER COLUMN duration_ms TYPE INTEGER;

ALTER TABLE videos ALTER COLUMN status DROP DEFAULT;
ALTER TABLE videos ALTER COLUMN status TYPE video_status USING status::video_status;
ALTER TABLE videos ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE videos
    ADD COLUMN climbing_session_id UUID,
    ADD COLUMN title TEXT,
    ADD COLUMN content_type TEXT,
    ADD COLUMN width SMALLINT,
    ADD COLUMN height SMALLINT,
    ADD COLUMN fps NUMERIC(6, 3),
    ADD COLUMN retained BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN visibility visibility NOT NULL DEFAULT 'private';

-- Existing rows only have the extension in their object key.
UPDATE videos
   SET content_type = CASE LOWER(SUBSTRING(object_key FROM '\.([A-Za-z0-9]+)$'))
                          WHEN 'mp4'  THEN 'video/mp4'
                          WHEN 'webm' THEN 'video/webm'
                          WHEN 'mov'  THEN 'video/quicktime'
                          WHEN 'avi'  THEN 'video/x-msvideo'
                          ELSE 'application/octet-stream'
                      END;

-- Completed videos used to keep their upload-URL expiry. Give them a retention
-- window so the new retention purge does not delete them right away.
UPDATE videos
   SET expires_at = NOW() + INTERVAL '365 days'
 WHERE status = 'completed';

ALTER TABLE videos
    ALTER COLUMN content_type SET NOT NULL,
    ADD CONSTRAINT videos_object_key_key UNIQUE (object_key),
    ADD CONSTRAINT fk_videos_climbing_session_id
        FOREIGN KEY (climbing_session_id)
        REFERENCES climbing_sessions(id)
        ON DELETE SET NULL;

CREATE INDEX idx_videos_user_created ON videos(user_id, created_at DESC);
CREATE INDEX idx_videos_climbing_session_id ON videos(climbing_session_id);
CREATE INDEX idx_videos_expiry ON videos(expires_at) WHERE retained = FALSE;

COMMIT;
