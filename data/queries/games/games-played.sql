SELECT name, count(*) FROM log
LEFT JOIN bgg ON bgg.id = log.id
GROUP BY name
ORDER BY name ASC
