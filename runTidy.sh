#!/usr/bin/env bash
set -euo pipefail

#-------------------------------------------------
# usage: display help and exit
#-------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0")

Checks for:
  • share/in.gtfs.zip
  • share/report.json

If either file is missing, you must run:
  ./runCheck.sh <your-feed.zip>

Otherwise, this script will start:
  docker-compose up pipFile
  docker-compose up tidy
EOF
}

# show help if requested
if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

#-------------------------------------------------
# Check required files
#-------------------------------------------------
if [[ ! -f share/in.gtfs.zip ]]; then
  echo "Error: 'share/in.gtfs.zip' not found. Please run './runCheck.sh' first." >&2
  exit 1
fi

if [[ ! -f share/report.json ]]; then
  echo "Error: 'share/report.json' not found. Please run './runCheck.sh' first." >&2
  exit 1
fi

#-------------------------------------------------
# Run Docker Compose services
#-------------------------------------------------
echo "▶ Starting 'pipFile' service..."
docker-compose up pipFile

echo "▶ Starting 'tidy' service..."
docker-compose up tidy
printf "✅ Pipeline completed successfully.\nTidy GTFS file is available at: %s/share/tidy.gtfs.zip\n" "$(pwd)"  
