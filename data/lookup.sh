#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: lookup game"
  exit 1
else
  game=$1
fi

sqlite-utils games.db "SELECT id, name, complexity, ranking FROM bgg WHERE name LIKE '%${game}%';"

