SELECT DISTINCT bgg.name FROM log
LEFT JOIN bgg on log.id = bgg.id
ORDER BY bgg.name
