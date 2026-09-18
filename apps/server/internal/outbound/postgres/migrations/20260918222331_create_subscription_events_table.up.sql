CREATE TYPE subscription_event_type AS ENUM (
    'created', 'activated', 'renewed', 'upgraded', 'downgraded',
    'payment_failed', 'canceled', 'expired'
);

CREATE TABLE subscription_events (
    id               UUID PRIMARY KEY DEFAULT uuidv7(),
    subscription_id  UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type             subscription_event_type NOT NULL,
    from_plan_code   TEXT REFERENCES subscription_plans(code),
    to_plan_code     TEXT REFERENCES subscription_plans(code)
    stripe_event_id  TEXT UNIQUE,
    payload          JSONB,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscription_events_user_occurred ON subscription_events(user_id, occurred_at DESC);
CREATE INDEX idx_subscription_events_type_occurred ON subscription_events(type, occurred_at DESC);
CREATE INDEX idx_subscription_events_subscription_id ON subscription_events(subscription_id);
