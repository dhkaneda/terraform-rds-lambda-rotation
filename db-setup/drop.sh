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

# Function to drop tables from a database
drop_tables() {
  local DB="$1"
  local TABLE=""
  
  # Determine which table to drop based on database name
  if [ "$DB" = "animals" ]; then
    TABLE="animals"
  elif [ "$DB" = "automobiles" ]; then
    TABLE="automobiles"
  else
    echo "Unknown database: $DB"
    return 1
  fi

  echo "Dropping table $TABLE from database $DB..."
  # Get table existence status
  EXISTS=$(psql -d "$DB" -t -c "\
    SELECT EXISTS (\
      SELECT 1 \
      FROM information_schema.tables \
      WHERE table_schema = 'public' \
      AND table_name = '$TABLE'\
    )")

  # Clean up whitespace
  EXISTS=$(echo "$EXISTS" | tr -d '[:space:]')

  # Check if table exists
  if [ "$EXISTS" = "t" ]; then
    echo "Dropping table $TABLE from database $DB..."
    psql -d "$DB" -c "DROP TABLE $TABLE;"
  else
    echo "Table $TABLE does not exist in database $DB. Skipping."
  fi
}

# Drop tables from each database
drop_tables animals
drop_tables automobiles

echo "All tables have been dropped."
