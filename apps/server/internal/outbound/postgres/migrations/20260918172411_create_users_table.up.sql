CREATE TYPE user_role AS ENUM ('user', 'admin', 'coach', 'gym');
CREATE TYPE user_status AS ENUM ('active', 'deactivated');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    username TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email VARCHAR(256) NOT NULL UNIQUE,
	password_hash TEXT NOT NULL,
	role user_role NOT NULL DEFAULT 'user',
	status user_status NOT NULL DEFAULT 'active',
	email_verified_at TIMESTAMPTZ,
	last_login_at TIMESTAMPTZ,
	deactivated_at TIMESTAMPTZ,
	stripe_customer_id TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_users_email_format
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_username_format
        CHECK (username ~ '^[a-z0-9_]{3,30}$'),
    CONSTRAINT chk_users_deactivation
        CHECK ((status = 'deactivated') = (deactivated_at IS NOT NULL))
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

CREATE TRIGGER update_users_updated_at
	BEFORE UPDATE ON users
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
