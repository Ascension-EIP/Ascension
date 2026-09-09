SELECT cron.unschedule('clean-expired-upload');

DROP EXTENSION IF EXISTS pg_cron;
