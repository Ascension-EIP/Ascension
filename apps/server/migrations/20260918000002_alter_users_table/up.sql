BEGIN;

ALTER TABLE users RENAME COLUMN password TO password_hash;

ALTER TABLE users
    ADD COLUMN username TEXT,
    ADD COLUMN first_name TEXT,
    ADD COLUMN last_name TEXT;

-- Existing "name" values were validated as handles (3-20 alphanumeric or underscore),
-- so they become the username. Invalid characters are stripped, short values padded,
-- and duplicates suffixed to satisfy the new format and uniqueness rules.
WITH stripped AS (
    SELECT id, LEFT(LOWER(REGEXP_REPLACE(name, '[^A-Za-z0-9_]', '', 'g')), 24) AS handle
      FROM users
), normalized AS (
    SELECT id,
           CASE WHEN LENGTH(handle) < 3 THEN RPAD(handle, 3, '_') ELSE handle END AS base
      FROM stripped
), ranked AS (
    SELECT id, base, ROW_NUMBER() OVER (PARTITION BY base ORDER BY id) AS rn
      FROM normalized
)
UPDATE users u
   SET username   = CASE WHEN r.rn = 1 THEN r.base ELSE r.base || '_' || r.rn END,
       first_name = u.name,
       last_name  = ''
  FROM ranked r
 WHERE r.id = u.id;

ALTER TABLE users
    ALTER COLUMN username SET NOT NULL,
    ALTER COLUMN first_name SET NOT NULL,
    ALTER COLUMN last_name SET NOT NULL,
    ADD CONSTRAINT users_username_key UNIQUE (username),
    DROP COLUMN name;

ALTER TABLE users ALTER COLUMN role DROP DEFAULT;
ALTER TABLE users ALTER COLUMN role TYPE user_role USING role::user_role;
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';

ALTER TABLE users
    ADD COLUMN status user_status NOT NULL DEFAULT 'active',
    ADD COLUMN email_verified_at TIMESTAMPTZ,
    ADD COLUMN last_login_at TIMESTAMPTZ,
    ADD COLUMN deactivated_at TIMESTAMPTZ,
    ADD COLUMN stripe_customer_id TEXT UNIQUE,
    ADD CONSTRAINT chk_users_email_format
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    ADD CONSTRAINT chk_users_username_format
        CHECK (username ~ '^[a-z0-9_]{3,30}$'),
    ADD CONSTRAINT chk_users_deactivation
        CHECK ((status = 'deactivated') = (deactivated_at IS NOT NULL));

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

COMMIT;
