CREATE TYPE body_zone AS ENUM (
    'head', 'neck', 'torso', 'lower_back',
    'left_shoulder', 'right_shoulder',
    'left_upper_arm', 'right_upper_arm',
    'left_elbow', 'right_elbow',
    'left_forearm', 'right_forearm',
    'left_wrist', 'right_wrist',
    'left_hand', 'right_hand',
    'left_fingers', 'right_fingers',
    'left_hip', 'right_hip',
    'left_thigh', 'right_thigh',
    'left_knee', 'right_knee',
    'left_shin', 'right_shin',
    'left_ankle', 'right_ankle',
    'left_foot', 'right_foot'
);
CREATE TYPE body_constraint_type AS ENUM ('missing', 'injured');

CREATE TABLE user_body_constraints (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    zone        body_zone NOT NULL,
    type        body_constraint_type NOT NULL,
    note        TEXT,
    started_at  DATE NOT NULL DEFAULT CURRENT_DATE,
    ended_at    DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_user_body_constraints_dates
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE INDEX idx_user_body_constraints_user_id ON user_body_constraints(user_id);
CREATE UNIQUE INDEX uq_user_body_constraints_active
    ON user_body_constraints(user_id, zone)
    WHERE ended_at IS NULL;

CREATE TRIGGER update_user_body_constraints_updated_at
    BEFORE UPDATE ON user_body_constraints
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
