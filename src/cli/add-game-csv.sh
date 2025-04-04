#!/bin/bash
# Insert one or more games into the BGG and notes table

if [ -z "$1" ]; then
  echo "Usage: $0 csv-file"
  exit 1
else
  CSV=$1
fi

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

DB="../../data/games.db"

echo "Adding game to table: bgg"
sqlite-utils insert ${DB} bgg ${CSV} --csv

echo "Adding game to table: notes"
GAME_ID=`basename $1 .csv`
sqlite-utils ${DB} "insert into notes (id, status, platform) values ($GAME_ID, 'Inbox', 'BGA');"

# The End
