CREATE TABLE videos (
	id         UUID        PRIMARY KEY DEFAULT uuidv7(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    object_key VARCHAR(64) NOT NULL,
    status     VARCHAR(32) NOT NULL DEFAULT 'pending',
	expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
);

CREATE INDEX idx_videos_user_id  ON videos(user_id);
CREATE INDEX idx_videos_status  ON videos(status);
CREATE INDEX idx_videos_expires_at ON videos(expires_at);

CREATE TRIGGER update_videos_updated_at
	BEFORE UPDATE ON videos
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
