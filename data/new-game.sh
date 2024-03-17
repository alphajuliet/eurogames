#!/bin/bash
# Upsert a game into the BGG table

if [ -z "$1" ]; then
  echo "Usage: new-game csv-file"
  exit 1
else
  CSV=$1
fi

sqlite-utils upsert games.db bgg ${CSV} --csv --detect-types --empty-null
