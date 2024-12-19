#!/bin/bash

# Creates a local backup of a remote SQL database using pg_dump
# Usage: db_dump.sh <base_dir> <db_host> <env_file> [retention_days]
# Restore: pg_restore -v -j 4 --clean -h <db_host> -U <db_user> -d <db_database> <backup_file>

set -e  # Exit on error

# Command-line arguments
base_dir=$1
db_host=$2
env_file=$3
retention_days=${4:-180}  # Default retention: 180 days

# Validate arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <base_dir> <db_host> <env_file> [retention_days]"
    exit 1
fi

# Load environment variables from .env file
if [ -f "$env_file" ]; then
    export $(grep -v '^#' "$env_file" | xargs)
else
    echo "Error: .env file not found at $env_file"
    exit 1
fi

# Check for required .env variables
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Error: POSTGRES_USER and POSTGRES_PASSWORD must be set in the .env file"
    exit 1
fi

# Optional: Database name from .env
db_database=${POSTGRES_DB:-mapineq}

# Get date
current_date=$(date +"%Y%m%d")

# Backup directory and dump file
backup_dir="${base_dir}/${current_date}"
dump_file="${backup_dir}/mapineq_${current_date}.backup"

# Make directory
mkdir -p "${backup_dir}"

# Initialize log file
log_file="${backup_dir}/log.txt"
printf "[%s] Starting backup: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "${dump_file}" >> "${log_file}"

# Redirect errors to log file
exec 2>>"${log_file}"

# Database dump
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_dump -F c -h "${db_host}" -U "${POSTGRES_USER}" -d "${db_database}" -f "${dump_file}"
unset PGPASSWORD

# Validate backup completion
if [ ! -f "${dump_file}" ]; then
    printf "[%s] Backup failed: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "${dump_file}" >> "${log_file}"
    exit 1
fi
printf "[%s] Backup completed: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "${dump_file}" >> "${log_file}"

# Delete backups older than retention period
find "${base_dir}" -mindepth 1 -maxdepth 1 -type d -mtime +"${retention_days}" -exec rm -rf {} \; \
    -exec printf "[%s] Deleted old backup: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" {} >> "${log_file}" \;

# Complete
printf "[%s] Backup process completed.\n\n" "$(date +'%Y-%m-%d %H:%M:%S')" >> "${log_file}"
