#!/bin/bash
# Insert one or more games into the BGG and notes table

if [ -z "$1" ]; then
  echo "Usage: add-game csv-file"
  exit 1
else
  CSV=$1
fi

echo "Adding game to table: bgg"
sqlite-utils insert games.db bgg ${CSV} --csv

echo "Adding game to table: notes"
GAME_ID=`basename $1 .csv`
sql games.db "insert into notes (id, status, platform) values ($GAME_ID, 'Evaluating', 'BGA');"

# The End
