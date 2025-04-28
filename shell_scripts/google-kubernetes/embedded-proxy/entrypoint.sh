#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Start the Cloud SQL Proxy in the background.
# Use the INSTANCE_CONNECTION_NAME environment variable.
# The '&' sends it to the background.
export DB_USER="${DB_USER}"
export DB_PASS="${DB_PASS}"
export DB_NAME="${DB_NAME}"
export INSTANCE_CONNECTION_NAME="${INSTANCE_CONNECTION_NAME}"
export GOOGLE_APPLICATION_CREDENTIALS="/app/key.json"
./cloud-sql-proxy --address 0.0.0.0 --port 3306 "${INSTANCE_CONNECTION_NAME}" &

# Wait a brief moment to allow the proxy to start (optional but sometimes helpful)
sleep 2

echo "Starting main application..."

# Activate the virtual environment
source /app/main/bin/activate
cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy

# Execute the command passed as arguments to this script (from CMD)
# 'exec' replaces the script process with the command, ensuring signals are handled correctly.
exec "$@"
