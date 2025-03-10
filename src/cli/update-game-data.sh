#!/bin/bash
# Update existing game data in the bgg table with latest BGG information

if [ -z "$1" ]; then
  echo "Usage: $0 game-id"
  exit 1
else
  ID=$1
fi

# if [ -z "$VIRTUAL_ENV" ]; then
#     echo "Starting virtual environment"
#     source ../venv/bin/activate
# fi

DB="../../data/games.db"

# Check if game exists in database first
if ! sqlite-utils ${DB} "SELECT 1 FROM bgg WHERE id = ${ID} LIMIT 1;" | grep -q 1; then
    echo "Error: Game ID ${ID} not found in database"
    exit 1
fi

BGG="/Users/andrew/LocalProjects/games/eurogames/src/sync/bgg.rkt"
CSV="${ID}.csv"

# Attempt to fetch BGG data
${BGG} ${ID} > "${CSV}"

if [ ! -s ${CSV} ]; then
    echo "Error: no data returned from BGG"
    rm -f "${CSV}"
    exit 1
fi

echo "Updating game in table: bgg"
sqlite-utils upsert ${DB} bgg ${CSV} --csv --pk=id

# Clean up
rm -f "${CSV}"

echo "Update complete for game ID: ${ID}"

# The End
