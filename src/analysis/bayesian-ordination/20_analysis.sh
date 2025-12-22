#!/usr/bin/env bash
#
# 20_analysis.sh
# Run the Bayesian latent variable analysis in the background via nohup.
#
# Usage:
#   ./20_analysis.sh /path/to/repository

set -euo pipefail

# 1) Require the repository root as argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/repository"
  exit 1
fi

REPO_DIR="$1"

# 2) Define the script and log relative to repo root
SCRIPT_PATH="src/analysis/bayesian-ordination/20_analysis.R"
LOG_DIR="wd/out/bayesian-ordination/analysis"
LOG_FILE="$LOG_DIR/analysis.log"

# 3) Switch into the repo, verify files exist
cd "$REPO_DIR"
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: R script not found at $SCRIPT_PATH"
  exit 1
fi

# 4) Ensure the log directory exists
mkdir -p "$LOG_DIR"

echo "Starting $SCRIPT_PATH with nohup..."
echo "  Log: $REPO_DIR/$LOG_FILE"

# 5) Launch in background and disown so it won’t hang up
nohup Rscript "$SCRIPT_PATH" > "$LOG_FILE" 2>&1 &
PID=$!
disown "$PID"

echo "Launched in background (PID $PID)."
