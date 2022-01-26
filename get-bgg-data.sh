#!/bin/bash

ARG='https://www.boardgamegeek.com/xmlapi2/thing?stats=1&id=50'
curl 'https://api.factmaven.com/xml-to-json/?xml='${ARG}
