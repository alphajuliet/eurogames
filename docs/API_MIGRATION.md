# Flask App Migration to REST API

This document describes the migration of the Flask web application from using local SQLite database to using the REST API at `https://eurogames.web-c10.workers.dev/`.

## Overview

The Flask application has been refactored to replace direct SQLite database access with HTTP API calls. This enables:

- **Decoupled Architecture**: Web app no longer requires local database file
- **Scalability**: API can be deployed independently and scaled separately
- **Network Resilience**: Graceful error handling for API failures
- **Future Flexibility**: API can be updated without changing the web app code

## Architecture Changes

### Before (SQLite Direct Access)

```python
from sqlite_utils import Database

db = Database("../../data/games.db")
games = db["game_list2"].rows
```

### After (REST API via HTTP Client)

```python
from api_client import EurogamesAPIClient

api_client = EurogamesAPIClient()
games = api_client.get_games_list()
```

## Implementation Details

### New API Client Module (`src/app/api_client.py`)

The `EurogamesAPIClient` class provides a clean interface to the REST API with the following features:

#### Authentication
- Uses HTTP Bearer Token authentication with API key
- API key provided via `EUROGAMES_API_KEY` environment variable
- All requests include the `Authorization: Bearer <api_key>` header

The class provides a clean interface to the REST API with the following methods:

#### Read Operations

- **`get_games_list(status="Playing")`** - Get games filtered by status
  - Returns: List of game dictionaries with status
  - API Endpoint: `GET /v1/games?status=<status>`

- **`get_all_games()`** - Get all games without filtering
  - Returns: List of all games
  - API Endpoint: `GET /v1/games`

- **`get_game_details(game_id)`** - Get detailed info for a single game
  - Returns: Game details dictionary
  - API Endpoint: `GET /v1/games/{id}`

- **`get_game_history(game_id)`** - Get play history for a game
  - Returns: List of play records for the game
  - API Endpoint: `GET /v1/games/{id}/history`

- **`get_played_results()`** - Get all game play results
  - Returns: List of played games with results
  - API Endpoint: `GET /v1/plays`

- **`get_recent_plays(limit=15)`** - Get recent game plays
  - Returns: List of recent plays
  - API Endpoint: `GET /v1/stats/recent?limit=<limit>`

- **`get_last_played()`** - Get last played dates
  - Returns: List of games with last played information
  - API Endpoint: `GET /v1/stats/last-played`

- **`get_winner_stats()`** - Get winner statistics
  - Returns: List of games with win statistics
  - API Endpoint: `GET /v1/stats/winners`

- **`get_totals()`** - Get aggregated win totals
  - Returns: Dictionary with total games, wins by player
  - API Endpoint: `GET /v1/stats/totals`

#### Write Operations

- **`add_game_result(date, game_id, winner, scores=None, comment=None)`** - Record a game result
  - Returns: True if successful
  - API Endpoint: `POST /v1/plays`
  - Request Body:
    ```json
    {
      "date": "YYYY-MM-DD",
      "game_id": <game_id>,
      "winner": "<player_name>",
      "scores": "<scores_string>",
      "comment": "<optional_comment>"
    }
    ```

### Configuration

#### Environment Variables

- **`EUROGAMES_API_URL`** (required)
  - Base URL of the REST API
  - Default: `https://eurogames.web-c10.workers.dev`
  - Example: `export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev`

- **`EUROGAMES_API_KEY`** (required for authenticated API)
  - API key for HTTP Basic Authentication
  - No default value - must be provided
  - Example: `export EUROGAMES_API_KEY=your-api-key-here`
  - Used in Authorization header: `Basic base64(key:)`

#### Timeout

- Request timeout is set to 10 seconds by default
- Can be customized when initializing the client:
  ```python
  api_client = EurogamesAPIClient(timeout=20)
  ```

#### Manual Authentication Configuration

If you need to pass credentials programmatically:

```python
api_client = EurogamesAPIClient(
    base_url="https://eurogames.web-c10.workers.dev",
    api_key="your-api-key"
)
```

### Error Handling

The API client raises `APIError` exceptions on network failures or invalid responses:

```python
from api_client import APIError

try:
    games = api_client.get_games_list()
except APIError as e:
    logger.error(f"Failed to fetch games: {e}")
    # Provide fallback or user-friendly error message
```

Both Flask (app.py) and FastHTML (main.py) applications handle API errors gracefully by:

1. Logging the error for debugging
2. Displaying user-friendly error messages
3. Returning empty data sets when appropriate
4. Redirecting to safe fallback pages

## Changes to Flask Routes

### Before
```python
@app.route("/games")
def games():
    db = Database(db_path)
    games = db["game_list2"].rows
    return render_template("games.html", games=games)
```

### After
```python
@app.route("/games")
def games():
    try:
        games_list = api_client.get_games_list()
        return render_template("games.html", games=games_list)
    except APIError as e:
        logger.error(f"API error: {e}")
        flash("Error fetching games", "error")
        return render_template("games.html", games=[])
```

## Changes to FastHTML Routes (main.py)

Similar error handling patterns were applied to all FastHTML routes:

```python
@rt('/games')
def get():
    try:
        games_data = api_client.get_games_list()
        games = makeRows(games_data, ['name', 'id', 'status', ...])
        return Table(...)
    except APIError as e:
        logger.error(f"API error: {e}")
        return P(f"Error loading games: {str(e)}")
```

## Dependencies

### Added
- `requests>=2.31.0` - HTTP client library

### Removed
- `sqlite-utils>=3.38` - No longer needed for direct database access

### Unchanged
- Flask, FastHTML, Jinja2 - Core web framework dependencies

Update dependencies with:
```bash
pip install -e .
# or
uv sync
```

## API Endpoint Assumptions

The implementation assumes the REST API provides the following endpoints. If your API has different endpoint paths or response formats, adjust the `api_client.py` accordingly:

```
GET  /api/games              - List all games
GET  /api/games?status=X     - List games by status
GET  /api/games/<id>         - Get single game details
GET  /api/results            - Get played game results
GET  /api/last-played        - Get last played dates
GET  /api/winner             - Get winner statistics
GET  /api/totals             - Get aggregated totals
POST /api/results            - Add new game result
```

## Response Format Expectations

The API client expects JSON responses in one of these formats:

### List Endpoints
```json
{
  "games": [
    {"id": 1, "name": "Game 1", ...},
    {"id": 2, "name": "Game 2", ...}
  ]
}
```
OR directly as an array:
```json
[
  {"id": 1, "name": "Game 1", ...},
  {"id": 2, "name": "Game 2", ...}
]
```

### Single Item Endpoints
```json
{
  "game": {"id": 1, "name": "Game 1", ...}
}
```
OR directly as an object:
```json
{"id": 1, "name": "Game 1", ...}
```

## Testing

### Local Development with Mock API

For testing without the actual API, you can:

1. Mock the API responses:
```python
# In test files
from unittest.mock import patch

with patch.object(api_client, 'get_games_list', return_value=[...]):
    response = client.get('/games')
```

2. Use a local development API server:
```bash
export EUROGAMES_API_URL=http://localhost:8787
./run-app.sh
```

### Testing Flask Routes

```bash
python -m pytest src/app/tests/
```

### Testing API Client Directly

```python
from api_client import EurogamesAPIClient

client = EurogamesAPIClient()
games = client.get_games_list()
print(f"Fetched {len(games)} games")
```

## Migration Checklist

- [x] Create API client module with all required methods
- [x] Update Flask routes to use API client
- [x] Update FastHTML routes to use API client
- [x] Add error handling to all routes
- [x] Update dependencies (pyproject.toml)
- [x] Update documentation
- [ ] Deploy API to production
- [ ] Update environment variables in deployment
- [ ] Test all endpoints with production API
- [ ] Monitor logs for any API errors
- [ ] Remove old SQLite database references from deployment

## Troubleshooting

### API Connection Errors

**Error**: `API request failed: Connection refused`

**Solution**:
- Verify the API URL is correct
- Check that the API server is running
- Test connectivity: `curl https://eurogames.web-c10.workers.dev/api/games`

### Timeout Errors

**Error**: `API request failed: Connection timeout`

**Solution**:
- Increase timeout: `EurogamesAPIClient(timeout=30)`
- Check API server performance
- Review network latency

### Empty Data

**Error**: Routes show empty tables even though API returns data

**Solution**:
- Check response format matches expectations
- Verify field names match template requirements
- Add logging to debug: `logger.debug(f"API response: {response}")`

### Authentication Errors

**Error**: `401 Unauthorized`

**Solution**:
- Check if API requires authentication
- Add authentication headers to `_get()` and `_post()` methods
- Store credentials in environment variables

## Future Improvements

1. **Response Caching**: Add client-side caching for read operations
2. **Retry Logic**: Implement exponential backoff for failed requests
3. **Pagination**: Support paginated API responses for large datasets
4. **WebSocket Support**: Real-time updates for game results
5. **GraphQL Option**: Alternative to REST API for flexible queries
6. **Offline Mode**: Fallback to cached data when API is unavailable

## Related Documentation

- [API Documentation](#) - REST API endpoint specifications
- [Deployment Guide](#) - Instructions for deploying the API
- [Database Schema](#) - Database structure and views
- [CLAUDE.md](./CLAUDE.md) - Project overview and architecture
