#!/bin/bash
# Insert one or more games into the BGG and notes table

if [ -z "$1" ]; then
  echo "Usage: add-game csv-file"
  exit 1
else
  CSV=$1
fi

sqlite-utils insert games.db bgg ${CSV} --csv

# The End
