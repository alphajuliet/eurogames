# Test and Documentation Directory

This folder contains test scripts and debugging/documentation files related to the API migration and Flask app integration.

## Structure

### `/scripts` - Test Scripts

Python and shell scripts for testing API connectivity and Flask endpoints:

- **test_api_debug.py** - Test all API endpoints and display response structure
- **test_api_response.py** - Inspect raw API response format
- **test_api_status_options.py** - Test different API query options for status filtering
- **test_all_statuses.py** - Check all games across all statuses from the API
- **test_winner_response.py** - Inspect winner endpoint response structure
- **test_games_list_change.py** - Test get_games_list() behavior changes
- **test_flask_games.sh** - Test Flask /games endpoint integration
- **test_all_endpoints.sh** - Test all Flask endpoints

### `/docs` - Documentation

Documentation and guides related to the API migration and fixes:

- **API_CLIENT_GUIDE.md** - Quick reference guide for API client usage with examples
- **API_FIX_SUMMARY.md** - Technical details of the API response format fix
- **WINNER_FIX_SUMMARY.md** - Technical details of the /winner endpoint fix
- **FIX_COMPLETION_SUMMARY.md** - Overall completion summary of all fixes
- **TEST_RESULTS_GAMES_LIST_CHANGE.md** - Test results for get_games_list() changes

## Running Tests

### Python Test Scripts

All Python test scripts require environment variables to be set:

```bash
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here
```

Then run from the project root:

```bash
# Test API connectivity
uv run python test/scripts/test_api_debug.py

# Test API status options
uv run python test/scripts/test_api_status_options.py

# Test games list changes
uv run python test/scripts/test_games_list_change.py

# Test all statuses
uv run python test/scripts/test_all_statuses.py
```

### Shell Test Scripts

```bash
# Test Flask endpoints
bash test/scripts/test_all_endpoints.sh

# Test Flask games page
bash test/scripts/test_flask_games.sh
```

## Key Findings

### API Migration Issues Fixed

1. **Response Format Mismatch** - API returns wrapped responses with `{"data": [...], "meta": {...}}`
   - Fixed in: `src/app/api_client.py`
   - Details: See `test/docs/API_FIX_SUMMARY.md`

2. **Winner Endpoint Data Transformation** - Field names didn't match template expectations
   - Fixed in: `src/app/app.py`
   - Details: See `test/docs/WINNER_FIX_SUMMARY.md`

3. **Games List Default Behavior** - Now returns all games across all statuses
   - Returns: 93 games (Playing, Inbox, Evaluating, Dropped, Unavailable, Not recommended)
   - Details: See `test/docs/TEST_RESULTS_GAMES_LIST_CHANGE.md`

## Important Documentation

For important user-facing documentation, see the project root:
- **README.md** - Project overview
- **QUICKSTART.md** - Getting started guide
- **API_MIGRATION.md** - Full API migration guide
- **API_DEPLOYMENT_CHECKLIST.md** - Deployment checklist
- **CLAUDE.md** - Project architecture and commands

## When to Use Tests

- **Before deploying**: Run `test_api_debug.py` to verify API connectivity
- **After API changes**: Run `test_api_status_options.py` to verify all statuses work
- **After Flask changes**: Run `test_all_endpoints.sh` to verify all routes work
- **Debugging issues**: Check relevant test script and documentation

## Environment Setup for Testing

```bash
# From project root
cd /Users/andrew/LocalProjects/games/eurogames

# Set environment variables
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here
export FLASK_SECRET_KEY=your-secret-key

# Install dependencies
uv sync

# Run tests
uv run python test/scripts/test_api_debug.py
```
