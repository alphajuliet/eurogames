#!/bin/bash
# Return a table of the last n played games

DB="../../data/games.db"
sqlite-utils $DB "SELECT * FROM last_played" --table

# The End
