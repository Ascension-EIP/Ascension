CREATE TABLE gyms (
    id             UUID PRIMARY KEY DEFAULT uuidv7(),
    owner_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
    name           TEXT NOT NULL,
    city           TEXT NOT NULL,
    country_code   CHAR(2) NOT NULL,
    address        TEXT,
    latitude       NUMERIC(9, 6),
    longitude      NUMERIC(9, 6),
    website_url    TEXT,
    is_partner     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_gyms_city ON gyms(country_code, city);
CREATE INDEX idx_gyms_owner_user_id ON gyms(owner_user_id);

CREATE TRIGGER update_gyms_updated_at
    BEFORE UPDATE ON gyms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

