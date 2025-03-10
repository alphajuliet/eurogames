#!/bin/bash
# Return the names of all the games we are playing

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

if [ -z "$1" ]; then
  STATUS="Playing"
else
  STATUS="$1"
fi
  
DB="../../data/games.db"
QUERY="SELECT bgg.name FROM notes
  LEFT JOIN bgg ON notes.id = bgg.id
  WHERE status = '${STATUS}'
  ORDER BY name ASC"

sqlite-utils ${DB} "${QUERY}" --table

# The End
