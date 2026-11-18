#!/usr/bin/env bash

# Creates the voters tables when the voters-db image initialises an empty database, run by the postgres image's
# entrypoint from /docker-entrypoint-initdb.d, see db/Dockerfile. The server only listens on its Unix socket during
# initialisation

set -euo pipefail

export PGHOST=/var/run/postgresql
export PGUSER="${POSTGRES_USER}"
export PGDATABASE="${POSTGRES_DB}"
export PGPASSWORD="${POSTGRES_PASSWORD}"
bash /opt/voters/bin/create-tables.sh
