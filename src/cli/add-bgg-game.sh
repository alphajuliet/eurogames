#!/bin/bash
# Grab a game from BGG and add it to the database as a new game

if [ -z "$1" ]; then
  echo "Usage: $0 game-id"
  exit 1
else
  ID=$1
fi

BGG="/Users/andrew/LocalProjects/games/eurogames/src/sync/bgg.rkt"
CSV="${ID}.csv"
${BGG} ${ID} > "${CSV}"

if [ ! -s ${CSV} ]; then
  echo "Error: no data returned from BGG"
  exit 1
fi

DB="../../data/games.db"

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

echo "Adding game to table: bgg"
sqlite-utils insert ${DB} bgg ${CSV} --csv

echo "Adding game to table: notes"
sqlite-utils ${DB} "INSERT INTO notes (id, status, platform) VALUES (${ID}, 'Inbox', 'BGA');"

rm ${CSV}

# The End
