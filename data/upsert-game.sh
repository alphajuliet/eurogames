#!/bin/bash
# Upsert one or more games into the BGG table

if [ -z "$1" ]; then
  echo "Usage: new-game csv-file"
  exit 1
else
  CSV=$1
fi

sqlite-utils upsert games.db bgg ${CSV} --csv --detect-types --pk=id

