#!/bin/bash
# List all the games in JSON

if [ -z "$1" ]; then
  JQ_ARG="."
else
  JQ_ARG=".data[] | select(.status == \"$1\")"
fi

curl -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${EUROGAMES_API_KEY}" \
   "${EUROGAMES_API_URL}/v1/games" | jq "${JQ_ARG}"

# The End
