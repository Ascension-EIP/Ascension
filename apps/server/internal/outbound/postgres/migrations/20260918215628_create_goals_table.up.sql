CREATE TYPE goal_status AS ENUM ('active', 'achieved', 'abandoned');
CREATE TYPE focus_area AS ENUM ('technique', 'strength', 'endurance', 'flexibility', 'mental');

CREATE TABLE goals (
    id                      UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status                  goal_status NOT NULL DEFAULT 'active',
    current_grade           TEXT NOT NULL,
    target_grade            TEXT NOT NULL,
    grading_system          grading_system NOT NULL,
    focus_areas             focus_area[] NOT NULL DEFAULT '{}',
    training_days_per_week  SMALLINT NOT NULL,
    target_date             DATE NOT NULL,
    achieved_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_goals_days CHECK (training_days_per_week BETWEEN 1 AND 7),
    CONSTRAINT chk_goals_achieved
        CHECK ((status = 'achieved') = (achieved_at IS NOT NULL))
);

CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE UNIQUE INDEX uq_goals_active ON goals(user_id) WHERE status = 'active';

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

