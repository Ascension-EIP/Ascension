CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule('clean-expired-sessions', '0 3 * * *', $$
    DELETE FROM sessions WHERE expires_at < NOW();
$$);
