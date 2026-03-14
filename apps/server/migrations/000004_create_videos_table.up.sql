CREATE TABLE videos (
	id UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id    UUID        NOT NULL,
    object_key TEXT        NOT NULL,
    status     TEXT        NOT NULL DEFAULT 'pending',
	expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_videos_user_id
        FOREIGN KEY (user_id)
		REFERENCES users(id) 
		ON DELETE CASCADE
);

CREATE INDEX idx_videos_user_id  ON videos(user_id);
CREATE INDEX idx_videos_status  ON videos(status);
CREATE INDEX idx_videos_expires_at ON videos(expires_at);

CREATE TRIGGER update_videos_updated_at
	BEFORE UPDATE ON users
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
