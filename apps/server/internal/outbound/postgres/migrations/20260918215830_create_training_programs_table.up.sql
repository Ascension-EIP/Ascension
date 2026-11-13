CREATE TYPE training_program_status AS ENUM ('draft', 'active', 'completed', 'archived');

CREATE TABLE training_programs (
    id                UUID PRIMARY KEY DEFAULT uuidv7(),
    goal_id           UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    author_user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    status            training_program_status NOT NULL DEFAULT 'draft',
    version           SMALLINT NOT NULL DEFAULT 1,
    title             TEXT NOT NULL,
    description       TEXT,
    duration_weeks    SMALLINT NOT NULL,
    starts_on         DATE,
    generation_input  JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_training_programs_duration CHECK (duration_weeks BETWEEN 1 AND 52),
    CONSTRAINT uq_training_programs_goal_version UNIQUE (goal_id, version)
);

CREATE INDEX idx_training_programs_author_user_id ON training_programs(author_user_id);
CREATE UNIQUE INDEX uq_training_programs_active ON training_programs(goal_id) WHERE status = 'active';

CREATE TRIGGER update_training_programs_updated_at
    BEFORE UPDATE ON training_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
