#!/bin/bash
# Update existing game data in the bgg table with latest BGG information

if [ -z "$1" ]; then
  echo "Usage: $0 game-id"
  exit 1
else
  ID=$1
fi

# Check if game exists in database first
RESP=`curl -s -H "Authorization: Bearer ${EUROGAMES_API_KEY}" -X GET ${EUROGAMES_API_URL}/v1/games/${ID} | jq -r ".error"`
if [ "$RESP" != "null" ] && [ -n "$RESP" ]; then
    echo "Error: Game ID ${ID} not found in database"
    exit 1
fi

BGG="/Users/andrew/LocalProjects/games/eurogames/src/sync/bgg.rkt"
CSV="${ID}.csv"
JSON="${ID}.json"

# Attempt to fetch BGG data
${BGG} ${ID} > "${CSV}"

if [ ! -s ${CSV} ]; then
    echo "Error: no data returned from BGG"
    rm -f "${CSV}"
    exit 1
fi

echo "# Updating game in database"
qsv select "complexity,rating,ranking" ${CSV} | qsv tojsonl > ${JSON}

curl -s -H "Authorization: Bearer ${EUROGAMES_API_KEY}" \
  -d @${JSON} \
  -X PATCH ${EUROGAMES_API_URL}/v1/games/${ID}/data

# Clean up
rm -f ${CSV} ${JSON}

echo "# Update complete for game ID: ${ID}"

# The End
