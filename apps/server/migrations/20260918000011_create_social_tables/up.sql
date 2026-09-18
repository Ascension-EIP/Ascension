CREATE TABLE friendships (
    id            UUID PRIMARY KEY DEFAULT uuidv7(),
    requester_id  UUID NOT NULL,
    addressee_id  UUID NOT NULL,
    status        friendship_status NOT NULL DEFAULT 'pending',
    responded_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_friendships_requester_id
        FOREIGN KEY (requester_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_friendships_addressee_id
        FOREIGN KEY (addressee_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_friendships_not_self CHECK (requester_id <> addressee_id),
    CONSTRAINT chk_friendships_responded
        CHECK ((status = 'pending') = (responded_at IS NULL))
);

-- One row per pair of users, whichever side sent the request.
CREATE UNIQUE INDEX uq_friendships_pair
    ON friendships(LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id));
CREATE INDEX idx_friendships_addressee_pending
    ON friendships(addressee_id) WHERE status = 'pending';

CREATE TRIGGER update_friendships_updated_at
    BEFORE UPDATE ON friendships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE follows (
    follower_id  UUID NOT NULL,
    followed_id  UUID NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (follower_id, followed_id),

    CONSTRAINT fk_follows_follower_id
        FOREIGN KEY (follower_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_follows_followed_id
        FOREIGN KEY (followed_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_follows_not_self CHECK (follower_id <> followed_id)
);

CREATE INDEX idx_follows_followed_id ON follows(followed_id);
