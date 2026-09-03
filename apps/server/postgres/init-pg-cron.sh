#!/usr/bin/env bash

echo "shared_preload_libraries = 'pg_cron'" >> "$PGDATA/postgresql.conf"
echo "cron.database_name = '${POSTGRES_DB:-postgres}'" >> "$PGDATA/postgresql.conf"
