#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: add-game date id winner scores"
  exit 1
else
  pdate=$1
  id=$2
  winner=$3
  scores=$4
fi

sqlite-utils games.db "INSERT INTO log ('date', 'id', 'winner', 'scores') VALUES
  ('$pdate', $id, '$winner', '$scores');"
