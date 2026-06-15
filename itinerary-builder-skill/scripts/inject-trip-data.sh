#!/bin/bash
set -e

# Injects trip data JSON into the bundled HTML shell, producing a single
# standalone HTML file with everything embedded.
#
# Usage:
#   bash scripts/inject-trip-data.sh <trip-data.json> [output.html]

TRIP_JSON="${1:?Usage: inject-trip-data.sh <trip-data.json> [output.html]}"
OUTPUT="${2:-itinerary.html}"

if [ ! -f "$TRIP_JSON" ]; then
  echo "Error: Trip data file not found: $TRIP_JSON"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_HTML="$SCRIPT_DIR/../assets/bundle-shell.html"

if [ ! -f "$SHELL_HTML" ]; then
  echo "Error: bundle-shell.html not found. Run the build first."
  exit 1
fi

# 1. Remove the external trip-data.js script tag (not needed when embedding)
# 2. Insert an embedded <script id="trip-data"> with the JSON right after <body>
node -e "
const fs = require('fs');
let shell = fs.readFileSync(process.argv[1], 'utf8');
const json = fs.readFileSync(process.argv[2], 'utf8');

// Remove external script references (not needed when embedding)
shell = shell.replace('<script src=\"trip-data.js\" onerror=\"\"><\/script>', '');
shell = shell.replace('<script src=\"trips.js\" onerror=\"\"><\/script>', '');

// Embed the JSON data
const tag = '<script id=\"trip-data\" type=\"application/json\">' + json.trim() + '<\/script>';
shell = shell.replace('<body>', '<body>' + tag);

fs.writeFileSync(process.argv[3], shell);
" "$SHELL_HTML" "$TRIP_JSON" "$OUTPUT"

FILE_SIZE=$(du -h "$OUTPUT" | cut -f1)
echo "Itinerary built: $OUTPUT ($FILE_SIZE)"
