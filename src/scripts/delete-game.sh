#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <id>"
  exit 1
else
  id=$1
fi

DB="../../data/games.db"
sqlite-utils "$DB" "DELETE FROM bgg WHERE id=$id"
sqlite-utils "$DB" "DELETE FROM notes WHERE id=$id"

# The End
