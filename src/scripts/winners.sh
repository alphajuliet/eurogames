#!/bin/bash
# List win stats for all games as a table

DB="../../data/games.db"
sqlite-utils $DB "SELECT * FROM winner" --table

# The End
