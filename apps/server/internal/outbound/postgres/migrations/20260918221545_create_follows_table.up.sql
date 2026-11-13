CREATE TABLE follows (
    follower_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (follower_id, followed_id),

    CONSTRAINT chk_follows_not_self CHECK (follower_id <> followed_id)
);

CREATE INDEX idx_follows_followed_id ON follows(followed_id);
