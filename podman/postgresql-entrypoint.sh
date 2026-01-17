#!/bin/bash
set -e

# PostgreSQL entrypoint script for Kubernetes-ready container

# Function to initialize PostgreSQL database
init_db() {
    # Ensure PGDATA directory exists and has correct permissions
    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA"
    
    if [ ! -s "$PGDATA/PG_VERSION" ]; then
        echo "Initializing PostgreSQL database..."
        initdb --username="$POSTGRES_USER" --pwfile=<(echo "$POSTGRES_PASSWORD") || initdb --username="$POSTGRES_USER"
        
        # Configure PostgreSQL for network access
        echo "Configuring PostgreSQL for network access..."
        {
            echo "host all all all scram-sha-256"
        } >> "$PGDATA/pg_hba.conf"
        
        {
            echo "listen_addresses = '*'"
            echo "max_connections = 100"
            echo "shared_buffers = 128MB"
            echo "dynamic_shared_memory_type = posix"
            echo "max_wal_size = 1GB"
            echo "min_wal_size = 80MB"
            echo "log_timezone = 'UTC'"
            echo "datestyle = 'iso, mdy'"
            echo "timezone = 'UTC'"
            echo "lc_messages = 'C'"
            echo "lc_monetary = 'C'"
            echo "lc_numeric = 'C'"
            echo "lc_time = 'C'"
            echo "default_text_search_config = 'pg_catalog.english'"
        } >> "$PGDATA/postgresql.conf"
        
        # Start PostgreSQL temporarily for initial setup
        pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
        
        # Create database if specified and different from default
        if [ "$POSTGRES_DB" != "postgres" ]; then
            echo "Creating database: $POSTGRES_DB"
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
                CREATE DATABASE "$POSTGRES_DB";
EOSQL
        fi
        
        # Set password if provided
        if [ -n "$POSTGRES_PASSWORD" ]; then
            echo "Setting password for user: $POSTGRES_USER"
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
                ALTER USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
EOSQL
        fi
        
        # Run initialization SQL scripts if they exist
        if [ -d /docker-entrypoint-initdb.d ]; then
            echo "Running initialization scripts..."
            for f in /docker-entrypoint-initdb.d/*; do
                case "$f" in
                    *.sh)
                        if [ -x "$f" ]; then
                            echo "Running $f"
                            "$f"
                        fi
                        ;;
                    *.sql)
                        echo "Running $f"
                        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$f"
                        ;;
                    *.sql.gz)
                        echo "Running $f"
                        gunzip -c "$f" | psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
                        ;;
                    *)
                        echo "Ignoring $f"
                        ;;
                esac
            done
        fi
        
        # Stop temporary PostgreSQL instance
        pg_ctl -D "$PGDATA" -m fast -w stop
        
        echo "PostgreSQL initialization complete."
    fi
}

# Main execution
if [ "$1" = 'postgres' ]; then
    # Initialize database if needed
    init_db
    
    # Start PostgreSQL in foreground
    echo "Starting PostgreSQL..."
    exec postgres
else
    # Execute any other command
    exec "$@"
fi
