#!/bin/bash
# List out all games as JSON

DB="../../data/games.db"
sqlite-utils $DB "SELECT * FROM game_list2" | jq '.'

# The End
