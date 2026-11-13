CREATE TABLE video_contexts (
	id UUID PRIMARY	KEY
);

CREATE TRIGGER update_video_contexts_updated_at
    BEFORE UPDATE ON video_contexts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
