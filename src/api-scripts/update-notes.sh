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

curl -X PATCH \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${EUROGAMES_API_KEY}" \
  -d "{\"$FIELD\": \"$VALUE\"}" \
   "${EUROGAMES_API_URL}/v1/games/${ID}/notes"

# The End
