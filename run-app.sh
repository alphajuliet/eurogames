#!/bin/bash

if [ -z "$VIRTUAL_ENV" ]; then
  echo "No virtual environment is active."
else
  echo "Virtual environment is active: $VIRTUAL_ENV"
  (cd src/app; flask run)
fi
