CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name VARCHAR(64) NOT NULL,
    email VARCHAR(256) NOT NULL UNIQUE,
	password TEXT NOT NULL,
	role VARCHAR(32) NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_users_role CHECK (role IN ('user', 'admin')),
    CONSTRAINT chk_users_email_lowercase CHECK (email = lower(email))
);

CREATE TRIGGER update_users_updated_at
	BEFORE UPDATE ON users
	FOR EACH ROW
	EXECUTE FUNCTION update_updated_at_column();
