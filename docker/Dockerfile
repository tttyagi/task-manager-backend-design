FROM postgres:17

COPY database/schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY database/seed.sql /docker-entrypoint-initdb.d/02-seed.sql