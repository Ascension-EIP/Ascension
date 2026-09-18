BEGIN;

DROP INDEX IF EXISTS idx_users_status;
DROP INDEX IF EXISTS idx_users_role;

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS chk_users_deactivation,
    DROP CONSTRAINT IF EXISTS chk_users_username_format,
    DROP CONSTRAINT IF EXISTS chk_users_email_format,
    DROP COLUMN IF EXISTS stripe_customer_id,
    DROP COLUMN IF EXISTS deactivated_at,
    DROP COLUMN IF EXISTS last_login_at,
    DROP COLUMN IF EXISTS email_verified_at,
    DROP COLUMN IF EXISTS status;

ALTER TABLE users ALTER COLUMN role DROP DEFAULT;
ALTER TABLE users ALTER COLUMN role TYPE TEXT USING role::TEXT;
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';

-- The old "name" column held the user handle, so it is restored from username.
ALTER TABLE users ADD COLUMN name TEXT;
UPDATE users SET name = username;
ALTER TABLE users
    ALTER COLUMN name SET NOT NULL,
    DROP CONSTRAINT IF EXISTS users_username_key,
    DROP COLUMN last_name,
    DROP COLUMN first_name,
    DROP COLUMN username;

ALTER TABLE users RENAME COLUMN password_hash TO password;

COMMIT;
