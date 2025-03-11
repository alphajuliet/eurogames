#!/bin/bash
# Return a table of the last n played games

if [ -z "$1" ]; then
  limit=10
else
  limit=$1
fi

DB="../../data/games.db"
sqlite-utils $DB "SELECT * FROM played LIMIT $limit" -t

# The End
