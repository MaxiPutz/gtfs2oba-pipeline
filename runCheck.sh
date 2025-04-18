#!/usr/bin/env bash
set -euo pipefail

#-------------------------------------------------
# usage: display help and exit
#-------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") /path/to/your-feed.zip

This script will:
  • Copy the GTFS zip into ./share/in.gtfs.zip
  • Start the 'valid' service:
      docker-compose up valid
  • Then start the 'check' service:
      docker-compose up check

Example:
  $ $(basename "$0") my-feed.zip
EOF
}

#-------------------------------------------------
# MAIN
#-------------------------------------------------
# 1) check args
if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

if [ "$#" -ne 1 ]; then
  echo "Error: missing GTFS ZIP file argument." >&2
  usage
  exit 1
fi

GTFS_ZIP="$1"
if [ ! -f "$GTFS_ZIP" ]; then
  echo "Error: file '$GTFS_ZIP' not found." >&2
  exit 1
fi

# 2) prepare share directory & copy the feed
mkdir -p share
cp "$GTFS_ZIP" share/in.gtfs.zip

# 3) run validation then checks
echo "▶ Running GTFS validation..."
docker-compose up valid                    # starts only the 'valid' service :contentReference[oaicite:0]{index=0}
echo "▶ Running GTFS checks..."
docker-compose up check                    # then starts only the 'check' service :contentReference[oaicite:1]{index=1}
