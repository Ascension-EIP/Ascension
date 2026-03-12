SELECT cron.unschedule('clean-expired-sessions');

DROP EXTENSION IF EXISTS pg_cron;
