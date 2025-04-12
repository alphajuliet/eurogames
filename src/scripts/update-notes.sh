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

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../venv/bin/activate
# fi

DB="../../data/games.db"

# Check if game exists in database first
if ! sqlite-utils ${DB} "SELECT 1 FROM bgg WHERE id = ${ID} LIMIT 1;" | grep -q 1; then
    echo "Error: Game ID ${ID} not found in database"
    exit 1
fi

echo "Updating game id $ID: $FIELD -> $VALUE"
sqlite-utils ${DB} "UPDATE notes SET $FIELD = \"$VALUE\" WHERE id = $ID;"

# The End
