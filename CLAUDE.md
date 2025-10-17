# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eurogames is a comprehensive board game tracking system that maintains a database of eurogames (board games), tracks game plays, and records results. The system integrates with Board Game Geek (BGG) to fetch game information and supports both local SQLite and cloud-based Cloudflare D1 databases.

## Architecture

The project uses a multi-language, multi-platform architecture:

- **CLI Tool (Babashka/Clojure)**: Primary interface in `src/cli/` for interacting with the system
- **Web Application (Python/Flask)**: Web interface in `src/app/` to view game data and results
- **Migration Tools**: Scripts for SQLite to Cloudflare D1 database migration
- **Sync Scripts (Racket)**: Scripts in `src/sync/` for fetching data from Board Game Geek
- **Analysis Tools (Julia)**: Data analysis scripts in `src/analysis/`

## Database Structure

**SQLite (Local Development)**: `data/games.db`
**Cloudflare D1 (Cloud Migration Target)**: Configured in `wrangler.toml`

Core tables:
- `bgg`: Game information from Board Game Geek
- `notes`: User-specific notes and status about games
- `log`: Game plays with dates, winners, and scores
- `saved_queries`: Custom SQL queries

Database views:
- `game_list2`: Games with notes and play statistics
- `played`: Game play history with details
- `last_played`: Last played dates for active games
- `winner`: Win statistics aggregated by game

## Common Commands

### CLI Commands

The primary interface is a Babashka CLI tool that can be invoked using the `games` command:

```bash
# Game Management
games list [status]                      # List games with a given status (default: Playing)
games search <pattern>                   # Search games by name/pattern
games show <id>                          # Show detailed game info
games add <bgg-id>                       # Add a new game from Board Game Geek
games sync <id>                          # Update game data from BGG

# Game Play Tracking
games play <id> <winner> [score]         # Record a game result
games history <id>                       # Show play history for a game
games last [limit]                       # Show when games were last played (default: 100)
games recent [limit]                     # Show recent game results (default: 15)

# Statistics & Analysis
games stats                              # Show win statistics and totals
games notes <id> <field> <value>         # Update game notes

# Utilities
games query <sql>                        # Run custom SQL query
games export <filename>                  # Export data to file
games backup                             # Create database backup
```

### Database Migration

To migrate data from SQLite to Cloudflare D1:

```bash
# Install migration dependencies (sqlite3 and wrangler)
npm install

# Export SQLite data to SQL files
npm run export-data

# Run complete migration process (exports data and imports to D1)
npm run migrate
# OR run the migration script manually:
./scripts/migrate-to-d1.sh
```

### Running the Web Application

```bash
# Start the Flask web server
./run-app.sh
```

### Development Commands

```bash
# Run Babashka (Clojure) REPL for CLI development
bb repl

# For Python web app development
# Install dependencies
pip install -e .

# Format Python code
black src/app

# Check Python code
flake8 src/app
```

## Output Formats

The CLI supports multiple output formats:
- `table` (default): Formatted table output
- `json`: JSON format
- `edn`: EDN (Clojure data) format
- `plain`: Plain text output

Change the output format with:
```bash
games -f json <command>
```

## Data Management

- **Local Database**: `data/games.db` (SQLite) - excluded from git via `.gitignore`
- **Cloud Database**: Cloudflare D1 - configured via `wrangler.toml` (migration target)
- **Backups**: Stored in `data/backup/`
- **Migration**: Use `./scripts/migrate-to-d1.sh` to migrate SQLite to D1
- **Common queries**: Located in `data/queries/games/`

## File Structure

```
src/
├── app/              # Flask web application
├── cli/              # Babashka CLI tool
├── sync/             # BGG sync scripts (Racket)
└── analysis/         # Data analysis (Julia)

migrations/           # D1 database migration files
scripts/              # Migration and utility scripts
data/                 # Local database and queries (gitignored)
```

## Configuration Files

- `wrangler.toml` - Cloudflare D1 database configuration for migration
- `package.json` - Node.js dependencies for migration scripts (sqlite3, wrangler)
- `MIGRATION.md` - Detailed database migration guide

## Migration Scripts

The project includes Node.js-based migration tools to export SQLite data to Cloudflare D1:

- `scripts/export-to-d1.js` - Exports SQLite tables to D1-compatible SQL INSERT statements
- `scripts/migrate-to-d1.sh` - Complete migration orchestration script
- `scripts/verify-migration.js` - Verification script for migration integrity

**Dependencies:**
- `sqlite3` - Node.js SQLite library for reading local database
- `wrangler` - Cloudflare CLI for D1 database operations