SELECT cron.unschedule('clean-old-quota-usages');
SELECT cron.unschedule('clean-expired-videos');
SELECT cron.unschedule('clean-abandoned-uploads');

SELECT cron.schedule('clean-expired-upload', '0 0 * * *', $$
    DELETE FROM videos WHERE expires_at < NOW() AND status != 'completed';
$$);

SELECT cron.schedule('clean-expired-sessions', '0 0 * * *', $$
    DELETE FROM sessions WHERE expires_at < NOW();
$$);
