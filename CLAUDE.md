# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eurogames is a board game tracking system that allows users to maintain a database of eurogames (board games), track game plays, and record results. The system integrates with Board Game Geek (BGG) to fetch and update game information and uses a local SQLite database for storage.

## Architecture

The project uses a multi-language architecture:

- **CLI Tool (Babashka/Clojure)**: Primary interface in `src/cli/` for interacting with the system
- **Web Application (Python/Flask)**: Web interface in `src/app/` to view game data and results
- **Shell Scripts**: Utility scripts in `src/scripts/` for common operations
- **Sync Scripts (Racket)**: Scripts in `src/sync/` for fetching data from Board Game Geek
- **Analysis Tools (Julia)**: Data analysis scripts in `src/analysis/`

## Database Structure

SQLite database (`games.db`) with tables:
- `bgg`: Game information from Board Game Geek
- `notes`: User-specific notes and status about games
- `log`: Game plays with dates, winners, and scores
- Various views like `game_list2`, `played`, `last_played`, and `winner`

## Common Commands

### CLI Commands

The primary interface is a Babashka CLI tool that can be invoked using the `games` command:

```bash
# List all games
games list

# List games with a specific status
games list owned

# Look up a game by name/pattern
games lookup <pattern>

# Get game details by ID
games id <id>

# Add a new game from Board Game Geek
games add-game <bgg-id>

# Record a game result
games add-result <id> <winner> <score>

# Update game data from BGG
games update <id>

# Update game notes
games update-notes <id> <field> <value>

# View game history
games history <id>

# View recent results
games results [limit]

# View last played games
games last [limit]

# View win statistics
games wins

# View total wins per player
games win-totals

# Run a custom SQL query
games query <sql>

# Export data
games export-data <filename>

# Backup database
games backup
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

- Database file: `games.db` (SQLite)
- Backups: Stored in `data/backup/`
- Common queries: Located in `data/queries/games/`