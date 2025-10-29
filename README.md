# Eurogames

A comprehensive board game tracking system that manages a collection of eurogames with data from Board Game Geek (BGG). The system includes a CLI tool and web interface for tracking games, recording plays, and analyzing statistics.

## Architecture

- **CLI Tool (Babashka/Clojure)**: Primary command-line interface for game management
- **Web Application (Python/Flask)**: Web interface for viewing games and recording results
- **Database**: SQLite locally, with Cloudflare D1 migration support
- **Sync Scripts (Racket)**: Tools for fetching data from Board Game Geek
- **Analysis Tools (Julia)**: Data analysis and statistics
- **API Scripts (Shell)**: Direct REST API shell scripts for querying and updating data

## Applications

### CLI Tool (`games` command)

The primary interface built with Babashka (Clojure):

```bash
# Game Management
games list [status]                      # List games by status (default: Playing)
games search <pattern>                   # Search games by name
games show <id>                          # Show detailed game information
games add <bgg-id>                       # Add new game from BGG
games sync <id>                          # Update game data from BGG

# Game Play Tracking
games play <id> <winner> [score]         # Record a game result
games history <id>                       # Show play history
games recent [limit]                     # Show recent results (default: 15)
games last [limit]                       # Show last played dates (default: 100)

# Statistics & Analysis
games stats                              # Show win statistics
games notes <id> <field> <value>         # Update game notes

# Utilities
games query <sql>                        # Run custom SQL queries
games export <filename>                  # Export data to JSON
games backup                             # Create database backup
```

### Web Application

Flask-based web interface that connects to REST API for:
- Browsing game collection
- Recording game results with forms
- Viewing statistics and win rates
- Game history and play tracking

**Requirements**: API authentication via `EUROGAMES_API_KEY` environment variable

### API Scripts

Direct REST API shell scripts for querying and updating data:

```bash
# List games in JSON format
./src/api-scripts/list-games.sh                  # List all games
./src/api-scripts/list-games.sh "Playing"        # Filter by status

# Update game notes
./src/api-scripts/update-notes.sh <id> <field> <value>
```

**Requirements**: Set `EUROGAMES_API_URL` and `EUROGAMES_API_KEY` environment variables

## Quick Start

### CLI Tool
```bash
# Install dependencies and run CLI
bb -m cli.games list
```

### Web Application
```bash
# Set required environment variables
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here
export FLASK_SECRET_KEY=your-secret-key

# Start the Flask web server
./run-app.sh
```

### Database Migration to Cloudflare D1
```bash
# Install Node.js dependencies for migration scripts
npm install

# Migrate from SQLite to Cloudflare D1
npm run migrate
```

## Features

- **Game Collection Management**: Track board games with BGG integration
- **Play Recording**: Log game sessions with winners and scores
- **Statistics**: Win rates, play frequency, player performance
- **Multi-format Output**: JSON, EDN, table, plain text formats
- **Data Export/Import**: Backup and restore game data
- **Search & Filtering**: Find games by name, status, complexity
- **Player Tracking**: Individual statistics and achievements
- **Cloud Migration**: Support for migrating data to Cloudflare D1
- **REST API Integration**: Web app communicates with remote API for scalable data access

## Testing

Test scripts and documentation are organized in the `test/` folder:

- **test/scripts/** - Automated test scripts for API endpoints and Flask routes
- **test/docs/** - Technical documentation, API guides, and fix summaries

To run tests:
```bash
# Test API connectivity
uv run python test/scripts/test_api_debug.py

# Test Flask endpoints
bash test/scripts/test_all_endpoints.sh

# See test/README.md for complete testing guide
```

See [test/README.md](test/README.md) for complete testing documentation.

