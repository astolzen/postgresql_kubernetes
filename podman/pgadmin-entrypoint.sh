#!/bin/bash
set -e

# pgAdmin4 entrypoint script for Kubernetes-ready container

# Set default values
export PGADMIN_DEFAULT_EMAIL="${PGADMIN_DEFAULT_EMAIL:-admin@example.com}"
export PGADMIN_DEFAULT_PASSWORD="${PGADMIN_DEFAULT_PASSWORD:-admin}"
export PGADMIN_LISTEN_ADDRESS="${PGADMIN_LISTEN_ADDRESS:-0.0.0.0}"
export PGADMIN_LISTEN_PORT="${PGADMIN_LISTEN_PORT:-8080}"

# Create config directory
mkdir -p /var/lib/pgadmin/config
mkdir -p /var/lib/pgadmin/sessions
mkdir -p /var/lib/pgadmin/storage
mkdir -p /var/log/pgadmin

# Create config_local.py if it doesn't exist
if [ ! -f /var/lib/pgadmin/config_local.py ]; then
    cat > /var/lib/pgadmin/config_local.py <<EOF
import os

# Server mode
SERVER_MODE = True

# Data directory
DATA_DIR = '/var/lib/pgadmin'
LOG_FILE = '/var/log/pgadmin/pgadmin4.log'
SQLITE_PATH = '/var/lib/pgadmin/pgadmin4.db'
SESSION_DB_PATH = '/var/lib/pgadmin/sessions'
STORAGE_DIR = '/var/lib/pgadmin/storage'

# Listen configuration
DEFAULT_SERVER = '${PGADMIN_LISTEN_ADDRESS}'
DEFAULT_SERVER_PORT = ${PGADMIN_LISTEN_PORT}

# Security
ENHANCED_COOKIE_PROTECTION = True
CSRF_ENABLED = True

# Disable master password requirement
MASTER_PASSWORD_REQUIRED = False

# Allow running as non-root
ALLOW_SAVE_PASSWORD = True

# Logging
CONSOLE_LOG_LEVEL = 'INFO'
FILE_LOG_LEVEL = 'INFO'
EOF
fi

# Set PYTHONPATH to include config directory
export PYTHONPATH=/var/lib/pgadmin:${PYTHONPATH}

# Initialize pgAdmin database if it doesn't exist
if [ ! -f /var/lib/pgadmin/pgadmin4.db ]; then
    echo "Initializing pgAdmin database..."
    # Use pgAdmin's setup with environment variable for non-interactive setup
    export PGADMIN_SETUP_EMAIL="${PGADMIN_DEFAULT_EMAIL}"
    export PGADMIN_SETUP_PASSWORD="${PGADMIN_DEFAULT_PASSWORD}"
    
    # Run pgAdmin setup to create initial database and user
    python3.11 -m pgadmin4.setup setup-db || echo "Database will be created on first web access"
fi

# Start pgAdmin
echo "Starting pgAdmin4..."
exec python3.11 -m pgadmin4.pgAdmin4
