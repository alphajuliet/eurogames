#!/bin/bash

# if [ -z "$VIRTUAL_ENV" ]; then
#   echo "Starting virtual environment"
#   source ../../venv/bin/activate
# fi
# echo "Virtual environment is active: $VIRTUAL_ENV"

(cd src/app; uv run flask run)
