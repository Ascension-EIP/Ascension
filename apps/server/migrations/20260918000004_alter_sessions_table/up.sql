BEGIN;

-- Refresh tokens are now random secrets stored only as a SHA-256 hash.
-- Existing sessions used their id as the token and cannot be converted:
-- they are dropped, so every user has to log in again once.
DELETE FROM sessions;

ALTER TABLE sessions
    ADD COLUMN token_hash TEXT NOT NULL,
    ADD COLUMN user_agent TEXT,
    ADD COLUMN ip_address INET,
    ADD COLUMN last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN revoked_at TIMESTAMPTZ,
    ADD CONSTRAINT sessions_token_hash_key UNIQUE (token_hash);

COMMIT;
