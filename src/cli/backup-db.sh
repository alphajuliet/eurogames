#!/bin/bash
# Back up the database

DB="../../data/games.db"
BACKUP_DIR="../../data/backup"
TODAY=`date -I`

cp ${DB} "${BACKUP_DIR}/games-${TODAY}.db"
echo "Created backup for ${TODAY}"

# The End
