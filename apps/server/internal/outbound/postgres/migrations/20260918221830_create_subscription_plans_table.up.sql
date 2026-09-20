CREATE TABLE subscription_plans (
    code                     TEXT PRIMARY KEY,
    name                     TEXT NOT NULL,
    price_cents              INTEGER NOT NULL,
    currency                 CHAR(3) NOT NULL DEFAULT 'EUR',
    monthly_analysis_quota   INTEGER NOT NULL,
    monthly_ghost_quota      INTEGER NOT NULL DEFAULT 0,
    ghost_mode_enabled       BOOLEAN NOT NULL DEFAULT FALSE,
    video_retention_enabled  BOOLEAN NOT NULL DEFAULT FALSE,
    ads_enabled              BOOLEAN NOT NULL DEFAULT TRUE,
    server_priority          BOOLEAN NOT NULL DEFAULT FALSE,
    stripe_price_id          TEXT UNIQUE,
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_subscription_plans_price CHECK (price_cents >= 0)
);

CREATE TRIGGER update_subscription_plans_updated_at
    BEFORE UPDATE ON subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Stripe price ids differ per environment and are set by an admin.
INSERT INTO subscription_plans
    (code, name, price_cents, monthly_analysis_quota, ghost_mode_enabled, ads_enabled, server_priority)
VALUES
    ('freemium', 'Freemium', 0,    10,  FALSE, TRUE,  FALSE),
    ('premium',  'Premium',  2000, 30,  TRUE,  FALSE, FALSE),
    ('infinity', 'Infinity', 3000, 100, TRUE,  FALSE, TRUE);
