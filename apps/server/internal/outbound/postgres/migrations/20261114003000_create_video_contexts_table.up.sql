-- Formerly 20260924221631: renamed so that databases already past that version
-- (production) apply it. IF NOT EXISTS and OR REPLACE keep it harmless on the
-- databases that already created the table under the old version.
CREATE TABLE IF NOT EXISTS video_contexts (
	id UUID PRIMARY	KEY
);

CREATE OR REPLACE TRIGGER update_video_contexts_updated_at
    BEFORE UPDATE ON video_contexts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
