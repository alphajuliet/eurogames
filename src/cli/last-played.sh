#!/bin/bash
# Return a table of the last n played games

if [ -z "$1" ]; then
  MAX=1000
else
  MAX="$1"
fi

DB="../../data/games.db"
sqlite-utils $DB "SELECT * FROM last_played LIMIT $MAX" --table

# The End
