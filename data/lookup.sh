#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: lookup <search-string>"
  exit 1
else
  game=$1
fi

if [ -z "$VIRTUAL_ENV" ]; then
  echo "Starting virtual environment"
  source ../venv/bin/activate
fi

sqlite-utils games.db "SELECT id, name, complexity, ranking FROM bgg WHERE name LIKE '%${game}%';"

# The End
