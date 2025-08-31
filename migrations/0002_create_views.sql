-- Create views for common queries
-- Note: D1 supports views as of 2024

-- Combined game list with notes and play stats
CREATE VIEW IF NOT EXISTS game_list2 AS 
SELECT 
    bgg.name, 
    bgg.id, 
    notes.status, 
    bgg.complexity, 
    bgg.ranking, 
    COALESCE(play_counts.games, 0) AS games,
    last_played_dates.lastPlayed,
    notes.uri
FROM bgg 
LEFT JOIN notes ON bgg.id = notes.id 
LEFT JOIN (
    SELECT id, COUNT(*) AS games 
    FROM log 
    GROUP BY id
) AS play_counts ON bgg.id = play_counts.id
LEFT JOIN (
    SELECT id, MAX(date) AS lastPlayed 
    FROM log 
    GROUP BY id
) AS last_played_dates ON bgg.id = last_played_dates.id
ORDER BY bgg.name;

-- Games with play details
CREATE VIEW IF NOT EXISTS played AS 
SELECT DISTINCT 
    log.date, 
    log.id, 
    bgg.name, 
    log.winner, 
    log.scores, 
    log.comment 
FROM log 
LEFT JOIN bgg ON bgg.id = log.id 
ORDER BY log.date DESC;

-- Win statistics by game and player
CREATE VIEW IF NOT EXISTS wins AS 
SELECT 
    bgg.name, 
    log.id, 
    log.winner, 
    COUNT(log.winner) AS wins 
FROM log
LEFT JOIN bgg ON log.id = bgg.id
GROUP BY bgg.name, log.id, log.winner;

-- Aggregated winner statistics
CREATE VIEW IF NOT EXISTS winner AS 
SELECT 
    bgg.name, 
    log.id,
    COUNT(*) AS Games,
    SUM(CASE WHEN log.winner = 'Andrew' THEN 1 ELSE 0 END) AS Andrew,
    SUM(CASE WHEN log.winner = 'Trish' THEN 1 ELSE 0 END) AS Trish,
    SUM(CASE WHEN log.winner = 'Draw' THEN 1 ELSE 0 END) AS Draw
FROM log
LEFT JOIN bgg ON log.id = bgg.id
GROUP BY bgg.name, log.id
ORDER BY bgg.name ASC;

-- Last played games for active collection
CREATE VIEW IF NOT EXISTS last_played AS 
SELECT 
    MAX(log.date) AS lastPlayed,
    julianday('now') - julianday(MAX(log.date)) AS daysSince,
    COUNT(log.date) AS games,
    log.id,
    bgg.name
FROM log
LEFT JOIN bgg ON log.id = bgg.id
LEFT JOIN notes ON log.id = notes.id
WHERE notes.status = 'Playing'
GROUP BY bgg.name, log.id
ORDER BY MAX(log.date) DESC;