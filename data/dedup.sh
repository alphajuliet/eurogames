#!/bin/bash

sqlite-utils games.db 'DELETE FROM log
WHERE rowid > (
  SELECT MIN(rowid) FROM log p2
  WHERE log.date = p2.date
  AND log.id = p2.id
  AND log.scores = p2.scores
);' 
# ORDER BY date DESC;'
