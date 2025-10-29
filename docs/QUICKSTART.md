# Quick Start Guide - Eurogames Flask App

## Setup

### 1. Install Dependencies
```bash
# From project root
pip install -e .
# OR
uv sync
```

### 2. Set Environment Variables

Before running the app, set these required environment variables:

```bash
# API Configuration
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here

# Flask Configuration
export FLASK_SECRET_KEY=your-secret-key-here
```

**⚠️ IMPORTANT**: Never commit API keys to version control. Use a `.env` file locally (not in git) or your deployment platform's secrets manager.

### 3. Verify API Connectivity (Optional)

Test that the API is accessible before running the app:

```bash
# Run the debug test script
python3 test_api_debug.py
```

This will show you:
- API connection status
- Number of items in each endpoint
- Response format details

## Running the App

### Development Mode

```bash
cd src/app
uv run flask run
```

The app will start on `http://localhost:5000`

### With Custom Port

```bash
cd src/app
uv run flask run --port 8000
```

### Production Mode

```bash
cd src/app
FLASK_ENV=production uv run flask run
```

## Pages Available

Once the app is running, you can access:

- **Home**: `http://localhost:5000/` - Main page
- **Games**: `http://localhost:5000/games` - Browse all games
- **Game Details**: `http://localhost:5000/game/6249` - Details for a specific game
- **Results**: `http://localhost:5000/results` - View and add game results
- **Last Played**: `http://localhost:5000/lastPlayed` - See when games were last played
- **Winners**: `http://localhost:5000/winner` - View win statistics
- **Totals**: `http://localhost:5000/totals` - View aggregated statistics (JSON)

## Testing the API

### Test All Endpoints
```bash
python3 test_api_debug.py
```

### Inspect API Response Format
```bash
python3 test_api_response.py
```

### Manual API Test with curl
```bash
API_KEY="your-api-key-here"

# Games endpoint
curl -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/games

# Game history
curl -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/games/6249/history

# Results/Plays
curl -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/plays

# Statistics
curl -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/stats/winners
```

## Logging

The app outputs debug information to the console. To see:

- **API requests/responses**: Check Flask console output
- **API response details**: Look for "Response status" and "Response data" messages
- **Route execution**: Check which route is being called

Example log output:
```
2025-10-18 14:44:55,106 - __main__ - INFO - Flask app starting up
2025-10-18 14:44:55,106 - __main__ - INFO - EUROGAMES_API_URL: https://eurogames.web-c10.workers.dev
2025-10-18 14:44:55,106 - api_client - DEBUG - API Client initialized - URL: https://eurogames.web-c10.workers.dev, API Key configured: True
2025-10-18 14:44:55,500 - __main__ - INFO - GET /games - route handler called
2025-10-18 14:44:55,525 - api_client - DEBUG - Response status: 200
```

## Troubleshooting

### "No module named 'requests'"
```bash
uv pip install requests
# OR
pip install requests
```

### "API request failed: 401 Unauthorized"
- Check that `EUROGAMES_API_KEY` is set correctly
- Verify the API key hasn't expired
- Test with curl manually

### No data showing on pages
1. Check Flask console for errors
2. Run `python3 test_api_debug.py` to verify API connectivity
3. Ensure `EUROGAMES_API_URL` is set to `https://eurogames.web-c10.workers.dev`

### Connection Refused
- Verify the API is accessible: `curl https://eurogames.web-c10.workers.dev/`
- Check network connectivity
- Verify `EUROGAMES_API_URL` is correct

## Environment File Example

Create a `.env` file in `src/app/` (not committed to git):

```bash
# .env
EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
EUROGAMES_API_KEY=fc4d3abc123def456ghi789jkl...
FLASK_SECRET_KEY=super-secret-key-here
FLASK_ENV=development
```

Then load it:
```bash
export $(cat .env | xargs)
uv run flask run
```

## Expected Data

The app should show:
- **49 games** in the games list (default "Playing" status)
- **15 recent results** in the results view
- **47 games** with last played dates
- **50 games** in winner statistics
- Various statistics and totals

## Next Steps

1. Configure your API key and secret key
2. Run `python3 test_api_debug.py` to verify API connectivity
3. Start the Flask app: `uv run flask run`
4. Navigate to `http://localhost:5000` in your browser
5. Browse games and add new results!

## Support

For issues:
1. Check `API_FIX_SUMMARY.md` for technical details
2. Review logs in Flask console output
3. Run test scripts to diagnose API issues
4. Check `API_MIGRATION.md` for API endpoint details
