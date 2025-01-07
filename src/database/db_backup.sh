#!/bin/bash

# Creates a monthly full backup and daily incremental backups of a PostgreSQL cluster using pg_basebackup
# Combines backups into a single restore-ready backup at the end of the month
# Usage: db_backup.sh <base_dir> <db_host> <env_file> [retention_days]

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

# Get current date
current_date=$(date +"%Y%m%d")
current_day=$(date +"%d")
current_month=$(date +"%Y%m")

# Monthly folder and backup filenames
monthly_dir="${base_dir}/${current_month}"
mkdir -p "${monthly_dir}"

if [ "$current_day" -eq 01 ]; then
    # Create a fresh full backup on the first of the month
    backup_dir="${monthly_dir}/0_mapineq_${current_date}"
    backup_manifest="${backup_dir}/backup_manifest"
    mkdir -p "$backup_dir"
    full_backup=true
else
    # Incremental backup for subsequent days
    last_increment=$(ls "${monthly_dir}" | grep -oE '^[0-9]+' | sort -n | tail -n 1)
    next_increment=$((last_increment + 1))
    backup_dir="${monthly_dir}/${next_increment}_mapineq_${current_date}"
    full_backup=false
fi

# Log file for the current month
log_file="${monthly_dir}/log.txt"
printf "[%s] Starting pg_basebackup to: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$backup_dir" >> "$log_file"

# Redirect errors to log file
exec 2>>"$log_file"

# ---- pg_basebackup ---- #
export PGPASSWORD="$POSTGRES_PASSWORD"
if [ "$full_backup" = true ]; then
    # Full backup
    pg_basebackup -h "$db_host" -U "$POSTGRES_USER" -D "$backup_dir" -Fp -Xs -v --write-recovery-conf
else
    # Incremental backup
    pg_basebackup -h "$db_host" -U "$POSTGRES_USER" --incremental="$monthly_dir/0_mapineq_${current_month}01/backup_manifest" -D "$backup_dir" -v
fi
unset PGPASSWORD
printf "[%s] Backup completed: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$backup_dir" >> "$log_file"
# ----------------------- #

# Combine backups at the end of the month
last_day_of_month=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +"%d")
if [ "$current_day" -eq "$last_day_of_month" ]; then
    combine_dir="${base_dir}/${current_month}_combine"
    mkdir -p "$combine_dir"
    backup_list=$(find "$monthly_dir" -mindepth 1 -maxdepth 1 -type d | sort)
    pg_combinebackup $backup_list -o "$combine_dir/"
    printf "[%s] Combined backups for %s into: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$current_month" "$combine_dir" >> "$log_file"

    # Delete the original backup directory
    rm -rf "$monthly_dir"
    printf "[%s] Deleted original backup directory: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$monthly_dir" >> "$log_file"
fi

# Delete backups older than retention period
find "$base_dir" -mindepth 1 -maxdepth 1 -type d -mtime +${retention_days} -exec rm -rf {} \; \
    -exec printf "[%s] Deleted old backup: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" {} >> "$log_file" \;

# Complete
printf "[%s] Backup process completed.\n\n" "$(date +'%Y-%m-%d %H:%M:%S')" >> "$log_file"
