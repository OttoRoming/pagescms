#!/bin/sh
set -eu

# Run pending migrations before starting the app. Set RUN_MIGRATIONS=false when
# migrations are handled by a separate deployment job.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  echo "Running database migrations..."
  node scripts/migrate.mjs
fi

exec "$@"
