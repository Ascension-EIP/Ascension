FROM postgres:18

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	postgresql-contrib \
	postgresql-18-cron \
	&& rm -rf /var/lib/apt/lists/*

COPY init-pg-cron.sh /docker-entrypoint-initdb.d/

EXPOSE 5432
