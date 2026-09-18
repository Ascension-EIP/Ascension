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

CREATE TABLE subscriptions (
    id                      UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id                 UUID NOT NULL,
    plan_code               TEXT NOT NULL,
    status                  subscription_status NOT NULL,
    stripe_subscription_id  TEXT UNIQUE,
    current_period_start    TIMESTAMPTZ NOT NULL,
    current_period_end      TIMESTAMPTZ NOT NULL,
    cancel_at_period_end    BOOLEAN NOT NULL DEFAULT FALSE,
    canceled_at             TIMESTAMPTZ,
    ended_at                TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_subscriptions_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_subscriptions_plan_code
        FOREIGN KEY (plan_code)
        REFERENCES subscription_plans(code),

    CONSTRAINT chk_subscriptions_period CHECK (current_period_end > current_period_start)
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE UNIQUE INDEX uq_subscriptions_current
    ON subscriptions(user_id) WHERE status IN ('trialing', 'active', 'past_due');
CREATE INDEX idx_subscriptions_period_end ON subscriptions(current_period_end)
    WHERE status IN ('trialing', 'active', 'past_due');

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE subscription_events (
    id               UUID PRIMARY KEY DEFAULT uuidv7(),
    subscription_id  UUID,
    user_id          UUID NOT NULL,
    type             subscription_event_type NOT NULL,
    from_plan_code   TEXT,
    to_plan_code     TEXT,
    stripe_event_id  TEXT UNIQUE,
    payload          JSONB,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_subscription_events_subscription_id
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_subscription_events_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_subscription_events_from_plan_code
        FOREIGN KEY (from_plan_code)
        REFERENCES subscription_plans(code),

    CONSTRAINT fk_subscription_events_to_plan_code
        FOREIGN KEY (to_plan_code)
        REFERENCES subscription_plans(code)
);

CREATE INDEX idx_subscription_events_user_occurred ON subscription_events(user_id, occurred_at DESC);
CREATE INDEX idx_subscription_events_type_occurred ON subscription_events(type, occurred_at DESC);
CREATE INDEX idx_subscription_events_subscription_id ON subscription_events(subscription_id);

CREATE TABLE quota_usages (
    user_id         UUID NOT NULL,
    period_start    DATE NOT NULL,
    analyses_count  INTEGER NOT NULL DEFAULT 0,
    ghosts_count    INTEGER NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, period_start),

    CONSTRAINT fk_quota_usages_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_quota_usages_period
        CHECK (period_start = DATE_TRUNC('month', period_start)::DATE),
    CONSTRAINT chk_quota_usages_counts
        CHECK (analyses_count >= 0 AND ghosts_count >= 0)
);

CREATE TRIGGER update_quota_usages_updated_at
    BEFORE UPDATE ON quota_usages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
