-- Initial schema migration for Eurogames D1 database
-- Created from existing SQLite schema

-- Board Game Geek data table
CREATE TABLE IF NOT EXISTS "bgg" (
   [id] INTEGER PRIMARY KEY,
   [yearPublished] INTEGER,
   [complexity] FLOAT,
   [playingTime] INTEGER,
   [mechanic] TEXT,
   [category] TEXT,
   [maxPlayers] INTEGER,
   [minPlayers] INTEGER,
   [name] TEXT,
   [rating] FLOAT,
   [ranking] INTEGER,
   [retrieved] TEXT
);

-- User notes and game status
CREATE TABLE IF NOT EXISTS "notes" (
   [id] INTEGER,
   [status] TEXT,
   [platform] TEXT,
   [uri] TEXT,
   [comment] TEXT
);

-- Game play log
CREATE TABLE IF NOT EXISTS "log" (
   [date] TEXT,
   [id] INTEGER,
   [winner] TEXT,
   [scores] TEXT,
   [comment] TEXT
);

-- Saved queries (if needed)
CREATE TABLE IF NOT EXISTS "saved_queries" (
   [name] TEXT PRIMARY KEY NOT NULL,
   [sql] TEXT NOT NULL,
   [author_id] TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bgg_name ON bgg(name);
CREATE INDEX IF NOT EXISTS idx_bgg_ranking ON bgg(ranking);
CREATE INDEX IF NOT EXISTS idx_notes_id ON notes(id);
CREATE INDEX IF NOT EXISTS idx_notes_status ON notes(status);
CREATE INDEX IF NOT EXISTS idx_log_date ON log(date DESC);
CREATE INDEX IF NOT EXISTS idx_log_id ON log(id);
CREATE INDEX IF NOT EXISTS idx_log_winner ON log(winner);