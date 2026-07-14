#!/bin/bash
echo "shared_preload_libraries = 'pg_cron'" >> "$PGDATA/postgresql.conf"
echo "cron.database_name = 'db'" >> "$PGDATA/postgresql.conf"
