# API Client Quick Reference

## Quick Start

```python
from api_client import EurogamesAPIClient, APIError

# Initialize client (reads EUROGAMES_API_URL and EUROGAMES_API_KEY from env)
client = EurogamesAPIClient()

# Or with custom URL, API key, and timeout
client = EurogamesAPIClient(
    base_url="https://eurogames.web-c10.workers.dev",
    api_key="your-api-key",
    timeout=15
)
```

## Usage Examples

### Fetching Games

```python
# Get "Playing" status games (default)
games = client.get_games_list()

# Get games with specific status
games = client.get_games_list(status="Completed")

# Get all games
games = client.get_all_games()
```

### Game Details

```python
# Get detailed info for game ID 123
game = client.get_game_details(123)
if game:
    print(f"Game: {game.get('name')}")
    print(f"Status: {game.get('status')}")

# Get play history for a specific game
history = client.get_game_history(123)
for play in history:
    print(f"Played on {play.get('date')}: {play.get('winner')} won")
```

### Play History & Statistics

```python
# Get all played games
results = client.get_played_results()

# Get recent game plays (last 15 by default)
recent = client.get_recent_plays()
for play in recent[:5]:
    print(f"{play.get('date')}: {play.get('winner')} won {play.get('name')}")

# Get recent plays with custom limit
recent_10 = client.get_recent_plays(limit=10)

# Get last played dates for all games
last_played = client.get_last_played()

# Get winner statistics
winners = client.get_winner_stats()

# Get aggregated totals
totals = client.get_totals()
print(f"Total games: {totals.get('Games')}")
print(f"Andrew wins: {totals.get('Andrew')}")
```

### Recording Results

```python
from datetime import datetime

# Record a new game result
success = client.add_game_result(
    date=datetime.now().strftime("%Y-%m-%d"),
    game_id=123,
    winner="Andrew",
    scores="12-8",
    comment="Great game!"
)

if success:
    print("Result recorded successfully")
```

## Error Handling

```python
from api_client import APIError

try:
    games = client.get_games_list()
except APIError as e:
    print(f"Failed to fetch games: {e}")
    # Handle error gracefully
    games = []
```

## Response Data Structures

### Game Object
```python
{
    'id': 123,
    'name': 'Carcassonne',
    'status': 'Playing',
    'complexity': 2.0,
    'ranking': 5234,
    'games': 42,
    'lastPlayed': '2024-10-18',
    # ... other fields
}
```

### Result Object
```python
{
    'date': '2024-10-18',
    'id': 123,
    'name': 'Carcassonne',
    'winner': 'Andrew',
    'scores': '12-8',
    # ... other fields
}
```

### Winner Stats Object
```python
{
    'name': 'Carcassonne',
    'Games': 42,
    'Andrew': 20,
    'Trish': 18,
    'Draw': 4,
    'AndrewRatio': 47.6
}
```

### Totals Object
```python
{
    'Games': 500,
    'Andrew': 250,
    'Trish': 200,
    'Draw': 50
}
```

## Configuration

### Environment Variables

```bash
# API URL (required)
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev

# API Key for authentication (required)
export EUROGAMES_API_KEY=your-api-key-here

# Flask secret key
export FLASK_SECRET_KEY=your-secret-key-here

# Python path (if needed)
export PYTHONPATH=/path/to/src/app
```

### Adjusting Timeout

```python
# Create client with custom timeout (in seconds)
client = EurogamesAPIClient(timeout=30)
```

## Common Patterns

### In Flask Routes

```python
from flask import Flask, render_template, flash
from api_client import EurogamesAPIClient, APIError

app = Flask(__name__)
api_client = EurogamesAPIClient()

@app.route("/games")
def games():
    try:
        games_list = api_client.get_games_list()
        return render_template("games.html", games=games_list)
    except APIError as e:
        flash("Error loading games", "error")
        return render_template("games.html", games=[])
```

### In FastHTML Routes

```python
from fasthtml.common import *
from api_client import EurogamesAPIClient, APIError

api_client = EurogamesAPIClient()

@rt('/games')
def get():
    try:
        games_data = api_client.get_games_list()
        # Process games_data...
        return render_games(games_data)
    except APIError as e:
        return error_message(f"Failed to load games: {e}")
```

### Form Submission (Adding Results)

```python
@app.route("/addResult", methods=["POST"])
def addResult():
    try:
        date = request.form.get('date')
        game_id = int(request.form.get('id'))
        winner = request.form.get('winner')
        scores = request.form.get('scores')
        comment = request.form.get('comment')

        success = api_client.add_game_result(
            date=date,
            game_id=game_id,
            winner=winner,
            scores=scores,
            comment=comment
        )

        if success:
            flash('Result added successfully', 'success')
        else:
            flash('Failed to add result', 'error')

    except ValueError:
        flash('Invalid input', 'error')
    except APIError as e:
        flash(f'API error: {str(e)}', 'error')

    return redirect(url_for('played'))
```

## Debugging

### Enable Logging

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Now API errors will be logged with full details
try:
    games = api_client.get_games_list()
except APIError as e:
    logger.debug(f"API Error: {e}")
```

### Test API Connectivity

```bash
# Set your API key
API_KEY="your-api-key-here"

# Test if API is accessible with Bearer token authentication
curl -H "Authorization: Bearer $API_KEY" \
     https://eurogames.web-c10.workers.dev/v1/games | jq '.'

# Test specific endpoint
curl -H "Authorization: Bearer $API_KEY" \
     https://eurogames.web-c10.workers.dev/v1/stats/totals | jq '.'

# Test with status filter
curl -H "Authorization: Bearer $API_KEY" \
     'https://eurogames.web-c10.workers.dev/v1/games?status=Playing' | jq '.'
```

### Inspect Responses

```python
import json

try:
    games = api_client.get_games_list()
    print(json.dumps(games, indent=2))
except APIError as e:
    print(f"Error: {e}")
```

## Customization

### Authentication Details

The API client automatically handles Bearer token authentication:

```python
# The API key from EUROGAMES_API_KEY environment variable is automatically
# added to all requests as: Authorization: Bearer <api_key>

# To verify authentication is working:
import os
from api_client import EurogamesAPIClient

client = EurogamesAPIClient()
print(f"API Key configured: {'Yes' if client.api_key else 'No'}")
print(f"API URL: {client.base_url}")

# Make test request
try:
    games = client.get_games_list()
    print(f"✓ Authentication successful! Got {len(games)} games")
except APIError as e:
    if '401' in str(e):
        print("✗ Authentication failed - check API key")
    else:
        print(f"✗ Error: {e}")
```

### Adding Caching

```python
from functools import lru_cache
from datetime import datetime, timedelta

class CachedAPIClient(EurogamesAPIClient):
    def __init__(self, *args, cache_ttl=300, **kwargs):
        super().__init__(*args, **kwargs)
        self.cache_ttl = cache_ttl
        self._cache = {}
        self._cache_time = {}

    def get_games_list(self, status="Playing"):
        cache_key = f"games_list_{status}"
        if self._is_cache_valid(cache_key):
            return self._cache[cache_key]

        result = super().get_games_list(status)
        self._cache[cache_key] = result
        self._cache_time[cache_key] = datetime.now()
        return result

    def _is_cache_valid(self, key):
        if key not in self._cache:
            return False
        age = datetime.now() - self._cache_time[key]
        return age < timedelta(seconds=self.cache_ttl)
```

## Migration from SQLite

### Find all Database References

```bash
# Find old sqlite_utils usage
grep -r "Database(" src/app/
grep -r "db\[" src/app/
grep -r "db\.query" src/app/
```

### Update Each Reference

Before:
```python
db = Database("path/to/games.db")
results = db["played"].rows
```

After:
```python
api_client = EurogamesAPIClient()
results = api_client.get_played_results()
```

## Troubleshooting

### Connection Refused
- Verify API URL is correct
- Check API server is running
- Check network connectivity

### Timeout
- Increase timeout: `EurogamesAPIClient(timeout=30)`
- Check API server performance

### Empty Results
- Verify API response format
- Check field names in response
- Add logging to debug

### Authentication Failed
- Check API token in environment variable
- Verify authentication headers are set
- Review API authentication requirements
