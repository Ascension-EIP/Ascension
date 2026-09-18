BEGIN;

-- Hashed tokens cannot be turned back into session-id tokens.
DELETE FROM sessions;

ALTER TABLE sessions
    DROP CONSTRAINT IF EXISTS sessions_token_hash_key,
    DROP COLUMN IF EXISTS revoked_at,
    DROP COLUMN IF EXISTS last_used_at,
    DROP COLUMN IF EXISTS ip_address,
    DROP COLUMN IF EXISTS user_agent,
    DROP COLUMN IF EXISTS token_hash;

COMMIT;
