-- init.sql — Run once when the Postgres container is first created.
-- Enables extensions required by the Prisma schema (pg_trgm, pgcrypto).
-- This file is mounted at /docker-entrypoint-initdb.d/ in the postgres container.

\c propertysales_db;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
