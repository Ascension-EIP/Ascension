-- cron.schedule() replaces a job that already has the same name.
SELECT cron.schedule('clean-expired-sessions', '0 0 * * *', $$
    DELETE FROM sessions
     WHERE expires_at < NOW()
        OR revoked_at < NOW() - INTERVAL '7 days';
$$);

-- Replaced by two jobs: abandoned uploads and expired completed videos.
SELECT cron.unschedule('clean-expired-upload');

SELECT cron.schedule('clean-abandoned-uploads', '0 * * * *', $$
    DELETE FROM videos
     WHERE status = 'pending' AND expires_at < NOW();
$$);

SELECT cron.schedule('clean-expired-videos', '0 2 * * *', $$
    DELETE FROM videos
     WHERE status = 'completed' AND retained = FALSE AND expires_at < NOW();
$$);

SELECT cron.schedule('clean-old-quota-usages', '0 3 1 * *', $$
    DELETE FROM quota_usages
     WHERE period_start < DATE_TRUNC('month', NOW()) - INTERVAL '24 months';
$$);
