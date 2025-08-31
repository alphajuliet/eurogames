# Eurogames

A comprehensive board game tracking system that manages a collection of eurogames with data from Board Game Geek (BGG). The system includes a CLI tool, web interface, and REST API for tracking games, recording plays, and analyzing statistics.

## Architecture

- **CLI Tool (Babashka/Clojure)**: Primary command-line interface for game management
- **Web Application (Python/Flask)**: Web interface for viewing games and recording results
- **REST API (TypeScript/Cloudflare Workers)**: Modern API layer using D1 database
- **Database**: SQLite locally, Cloudflare D1 for production API
- **Sync Scripts (Racket)**: Tools for fetching data from Board Game Geek
- **Analysis Tools (Julia)**: Data analysis and statistics

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

### REST API (Cloudflare Workers)

Modern TypeScript API deployed on Cloudflare Workers with D1 database and API key authentication:

**Base URL:** `https://your-worker.your-subdomain.workers.dev`

#### Authentication
The API requires authentication via API keys with role-based permissions:

```bash
# Using Authorization header
curl -H "Authorization: Bearer your-api-key" https://api.example.com/v1/games

# Using X-API-Key header
curl -H "X-API-Key: your-api-key" https://api.example.com/v1/plays
```

**Permission Levels:**
- **Admin**: Full access (read, write, delete, export, query)
- **User**: Standard access (read, write)
- **Read-only**: View-only access (read)

#### Games Management
- `GET /v1/games` - List games with filtering, pagination, search **[read]**
- `GET /v1/games/{id}` - Get detailed game info with stats **[read]**
- `POST /v1/games` - Add new game from BGG **[write]**
- `PATCH /v1/games/{id}/notes` - Update game notes and status **[write]**
- `GET /v1/games/{id}/history` - Get game play history **[read]**

#### Play Tracking
- `GET /v1/plays` - List game plays with filtering **[read]**
- `POST /v1/plays` - Record new game result **[write]**
- `GET /v1/plays/{id}` - Get specific play record **[read]**
- `PUT /v1/plays/{id}` - Update play record **[write]**
- `DELETE /v1/plays/{id}` - Delete play record **[delete]**

#### Statistics & Analytics
- `GET /v1/stats/winners` - Win statistics by game **[read]**
- `GET /v1/stats/totals` - Overall win totals **[read]**
- `GET /v1/stats/last-played` - Last played dates **[read]**
- `GET /v1/stats/recent` - Recent game plays **[read]**
- `GET /v1/stats/players/{player}` - Player statistics **[read]**
- `GET /v1/stats/games` - Collection statistics **[read]**

#### Utilities
- `GET /v1/export` - Export all data as JSON **[export]**
- `POST /v1/query` - Execute custom SELECT queries **[query]**

### Web Application

Flask-based web interface for:
- Browsing game collection
- Recording game results with forms
- Viewing statistics and win rates
- Game history and play tracking

## Quick Start

### CLI Tool
```bash
# Install dependencies and run CLI
bb -m cli.games list
```

### REST API Development
```bash
# Install dependencies
npm install

# Set up authentication (required for production)
wrangler secret put API_KEYS
# Enter: admin-key:admin,user-key:user,readonly-key:read-only

# Run locally (auth disabled in dev mode)
npm run dev

# Deploy to Cloudflare
npm run deploy
```

### Database Migration
```bash
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
- **Secure REST API**: Role-based authentication with API keys
- **Cloud Database**: Cloudflare D1 for scalable data storage
- **CORS Support**: Cross-origin requests for web applications

