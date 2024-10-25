#!/bin/bash
# Update a game ranking

if [ $# -ne 2 ]; then
  echo "Usage: update-ranking <id> <new-value>"
  exit 1
else
  ID=$1
  RANK=$2
fi

if [ -z "$VIRTUAL_ENV" ]; then
  echo "Starting virtual environment"
  source ../venv/bin/activate
fi

echo "Updating game id $ID with rank $RANK"
sqlite-utils games.db "UPDATE bgg SET ranking = \"$RANK\" WHERE id = $ID;"

# The End
