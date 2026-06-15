#!/bin/bash
set -e

# Converts a trip-data.json into a self-registering *.trip.js file
# that pushes onto window.__TRIPS__.
#
# Usage:
#   bash scripts/create-trip-file.sh <trip-data.json> <slug> [output-dir]
#
# Example:
#   bash scripts/create-trip-file.sh galena-trip.json galena-2026 ./trips
#
# Output: <output-dir>/<slug>.trip.js

TRIP_JSON="${1:?Usage: create-trip-file.sh <trip-data.json> <slug> [output-dir]}"
SLUG="${2:?Usage: create-trip-file.sh <trip-data.json> <slug> [output-dir]}"
OUTPUT_DIR="${3:-.}"

if [ ! -f "$TRIP_JSON" ]; then
  echo "Error: Trip data file not found: $TRIP_JSON"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/${SLUG}.trip.js"

node -e "
const fs = require('fs');
const json = fs.readFileSync(process.argv[1], 'utf8');
// Validate it's valid JSON
JSON.parse(json);
const content = 'window.__TRIPS__ = window.__TRIPS__ || [];\nwindow.__TRIPS__.push(' + json.trim() + ');\n';
fs.writeFileSync(process.argv[2], content);
" "$TRIP_JSON" "$OUTPUT_FILE"

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "Trip file created: $OUTPUT_FILE ($FILE_SIZE)"
