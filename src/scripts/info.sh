#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: info <id>"
  exit 1
else
  id=$1
fi

DB="../../data/games.db"
sqlite-utils "${DB}" \
  "SELECT * FROM bgg \
  LEFT JOIN notes on bgg.id = notes.id \
  WHERE bgg.id=$id" | jq "."

# The End
