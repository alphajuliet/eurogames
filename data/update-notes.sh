#!/bin/bash
# Update a field in the notes table

if [ $# -ne 3 ]; then
  echo "Usage: update-notes <id> <field> <value>"
  exit 1
else
  ID=$1
  FIELD=$2
  VALUE=$3
fi

if [ -z "$VIRTUAL_ENV" ]; then
  echo "Starting virtual environment"
  source ../venv/bin/activate
fi

echo "Updating game id $ID: $FIELD -> $VALUE"
sqlite-utils games.db "UPDATE notes SET $FIELD = \"$VALUE\" WHERE id = $ID;"

# The End
