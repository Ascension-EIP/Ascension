CREATE TYPE analysis_type AS ENUM ('2d', '3d');

CREATE TABLE analyses (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    video_id UUID NOT NULL,
    type analysis_type NOT NULL DEFAULT '2d',
    status TEXT NOT NULL DEFAULT 'pending',
    progress INTEGER NOT NULL DEFAULT 0,
    result JSONB,
    hints TEXT,
    error TEXT,
    processing_time INTEGER,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_analyses_video_id
        FOREIGN KEY (video_id)
        REFERENCES videos(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_analyses_video_id_type
        UNIQUE (video_id, type)
);

CREATE INDEX idx_analyses_video_id ON analyses(video_id);
CREATE INDEX idx_analyses_status ON analyses(status);
CREATE INDEX idx_analyses_video_id_type ON analyses(video_id, type);

CREATE TRIGGER update_analyses_updated_at
    BEFORE UPDATE ON analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
