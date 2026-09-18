CREATE TYPE video_status AS ENUM ('pending', 'completed');
CREATE TYPE visibility AS ENUM ('private', 'friends', 'public');

CREATE TABLE videos (
	id          UUID        PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    object_key  TEXT NOT NULL UNIQUE,
	climbing_session_id UUID REFERENCES users(id) ON DELETE SET NULL,
	title TEXT,
    status      video_status NOT NULL DEFAULT 'pending',
	visibility visibility NOT NULL DEFAULT 'private',
	width SMALLINT,
	height SMALLINT,
	fps NUMERIC(6, 3),
	content_type TEXT NOT NULL,
    duration_ms INTERVAL,
    size_bytes  BIGINT,
	retained BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_videos_user_created ON videos(user_id, created_at DESC);
CREATE INDEX idx_videos_climbing_session_id ON videos(climbing_session_id);
CREATE INDEX idx_videos_expiry ON videos(expires_at) WHERE retained = FALSE;

CREATE TRIGGER update_videos_updated_at
	BEFORE UPDATE ON videos
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
