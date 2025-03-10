#!/bin/bash
# Grab a game from BGG and store as CSV

if [ -z "$1" ]; then
  echo "Usage: $0 game-id"
  exit 1
else
  ID=$1
fi

BGG="/Users/andrew/LocalProjects/games/eurogames/src/sync/bgg.rkt"
CSV="${ID}.csv"
${BGG} ${ID} > "${CSV}"

if [ ! -s ${CSV} ]; then
  echo "Error: no data returned from BGG"
  exit 1
fi

cat ${CSV}

# The End
