#!/bin/bash
set -euo pipefail
set -x

# Required env vars: TF_VAR_rds_endpoint, TF_VAR_rds_master_user, TF_VAR_rds_master_secret
# Parse TF_VAR_rds_endpoint into PGHOST and PGPORT
export PGHOST=$(echo "$TF_VAR_rds_endpoint" | cut -d: -f1)
export PGPORT=$(echo "$TF_VAR_rds_endpoint" | cut -d: -f2)
# Fallback to 5432 if port is missing
if [ -z "$PGPORT" ] || [ "$PGPORT" = "$TF_VAR_rds_endpoint" ]; then
  export PGPORT=5432
fi
export PGUSER="${TF_VAR_rds_master_user}"
# Fetch the master password from AWS Secrets Manager using the ARN
export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id "$TF_VAR_rds_master_secret_arn" --query SecretString --output text | jq -r .password)

echo "PGHOST=$PGHOST"
echo "PGPORT=$PGPORT"

APP_USER="app_user"
APP_PASS="${APP_USER_PASSWORD:-changeme}" # Set via env or secret in pipeline

# Create databases if they don't exist
for DB in animals automobiles; do
  echo "Ensuring database $DB exists..."
  psql -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB';" | grep -q 1 || \
    psql -d postgres -c "CREATE DATABASE $DB;"
done

# Function to setup schema and seed data
setup_db() {
  local DB="$1"
  local SEED_SQL="$2"

  echo "Seeding data (and schema if needed) from $SEED_SQL into $DB..."
  psql -d "$DB" -f "$SEED_SQL"
}

# Setup and seed each DB
setup_db animals seed-pg-animals.sql
setup_db automobiles seed-pg-autos.sql

# Create app user if not exists, and set password
echo "Ensuring user $APP_USER exists..."
psql -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$APP_USER';" | grep -q 1 || \
  psql -d postgres -c "CREATE USER $APP_USER WITH PASSWORD '$APP_PASS';"

# Grant CRUD (CONNECT, USAGE, SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER) on all tables in both DBs
for DB in animals automobiles; do
  echo "Granting privileges on $DB to $APP_USER..."
  psql -d "$DB" -c "GRANT CONNECT ON DATABASE $DB TO $APP_USER;"
  psql -d "$DB" -c "GRANT USAGE ON SCHEMA public TO $APP_USER;"
  psql -d "$DB" -c "GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO $APP_USER;"
  # Ensure future tables also get these privileges
  psql -d "$DB" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO $APP_USER;"
done

echo "Database setup complete."