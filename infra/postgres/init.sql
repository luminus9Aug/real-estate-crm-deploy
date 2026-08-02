-- init.sql — Run once on first Postgres container boot.
-- Executed by the postgres superuser inside 'propertysales_db'
-- (POSTGRES_DB is already set, so no \c needed — initdb already connects to it).
--
-- Purpose:
--   1. Pre-create pg_trgm + pgcrypto as superuser so the app user
--      (propertysales) never has to, which would fail with
--      "must be superuser to create this extension".
--   2. Grant SUPERUSER temporarily just for extension creation is NOT needed
--      because we create them here as postgres.

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Allow the app user to use the extensions
GRANT ALL PRIVILEGES ON DATABASE propertysales_db TO propertysales;
