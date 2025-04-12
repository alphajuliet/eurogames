#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: lookup <search-string>"
  exit 1
else
  game=$1
fi

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

DB="../../data/games.db"
sqlite-utils "${DB}" \
  "SELECT * FROM bgg \
  LEFT JOIN notes on bgg.id = notes.id \
  WHERE name LIKE '%${game}%';" | jq "."

# The End
