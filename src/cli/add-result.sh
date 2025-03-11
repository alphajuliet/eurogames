#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 id winner scores"
  echo "winner must be one of: Andrew, Trish, or Draw"
  echo "scores should be a string of the form a:b"
  exit 1
else
  pdate=`date -I`
  id=$1
  winner=$2
  scores=$3
fi

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

DB="../../data/games.db"

sqlite-utils $DB "INSERT INTO log ('date', 'id', 'winner', 'scores') VALUES
  ('$pdate', $id, '$winner', '$scores');"

# The End
