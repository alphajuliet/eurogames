#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: add-game date id winner scores"
  exit 1
else
  pdate=$1
  id=$2
  winner=$3
  scores=$4
fi

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

DB="../../data/games.dn"

sqlite-utils ${DB} "INSERT INTO log ('date', 'id', 'winner', 'scores') VALUES
  ('$pdate', $id, '$winner', '$scores');"
