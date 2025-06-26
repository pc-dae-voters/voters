#!/usr/bin/env bash
set -e

# Source the AWS RDS environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_ENV="${SCRIPT_DIR}/../infra/aws/db/db-env.sh"

if [ -f "$DB_ENV" ]; then
  source "$DB_ENV"
else
  echo "ERROR: db-env.sh not found at $DB_ENV"
  exit 1
fi

# Build the application
cd "${SCRIPT_DIR}/../voters-api"
mvn clean package -DskipTests

# Run the application
java -jar target/voters-api-0.0.1.jar 