#!/bin/bash

# ─── ARGUMENT PARSING ────────────────────────────────────────────────

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -osmPath) osmPath="$2"; shift ;;
        -gtfsPath) gtfsPath="$2"; shift ;;
        *) echo "❌ Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# ─── CHECK ARGUMENTS ─────────────────────────────────────────────────

if [[ -z "$osmPath" || -z "$gtfsPath" ]]; then
    echo "❌ Usage: ./opt-build.sh -osmPath path/to/file.osm.pbf -gtfsPath path/to/file.gtfs.zip"
    exit 1
fi

# ─── PREPARE FOLDER ──────────────────────────────────────────────────

mkdir -p ./share/data

# ─── COPY FILES ──────────────────────────────────────────────────────

echo "📦 Copying OSM file from: $osmPath"
cp "$osmPath" ./share/data || { echo "❌ Failed to copy OSM file."; exit 1; }

echo "📦 Copying GTFS file from: $gtfsPath"
cp "$gtfsPath" ./share/data || { echo "❌ Failed to copy GTFS file."; exit 1; }

# ─── RUN DOCKER ──────────────────────────────────────────────────────

echo "🐳 Starting OTP build container..."
sudo docker-compose up otp-build
