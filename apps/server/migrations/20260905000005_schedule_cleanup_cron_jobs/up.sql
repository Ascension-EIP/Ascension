CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule('clean-expired-sessions', '0 0 * * *', $$
    DELETE FROM sessions WHERE expires_at < NOW();
$$);

SELECT cron.schedule('clean-expired-upload', '0 0 * * *', $$
    DELETE FROM videos WHERE expires_at < NOW() AND status != 'completed';
$$);
