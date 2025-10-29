# API Deployment & Testing Checklist

This checklist guides you through deploying and testing the migrated Flask application with the REST API.

## Pre-Deployment

### 1. Verify API Deployment
- [ ] REST API is deployed at `https://eurogames.web-c10.workers.dev/`
- [ ] API is accessible and responding to requests
- [ ] API database (D1) is accessible and contains data

**Test Command** (with Bearer token authentication):
```bash
# Set your API key
API_KEY="your-api-key-here"

# Test with Bearer token
curl -s -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/games | jq '.' | head -20
```

**Alternative endpoints to test**:
```bash
API_KEY="your-api-key-here"

# Test games endpoint
curl -s -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/games

# Test stats endpoint
curl -s -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/stats/totals

# Test plays endpoint
curl -s -H "Authorization: Bearer $API_KEY" \
  https://eurogames.web-c10.workers.dev/v1/plays
```

### 2. Verify API Response Format
- [ ] `/v1/games` returns game objects with expected fields
- [ ] `/v1/plays` returns play/result objects with expected fields
- [ ] `/v1/stats/totals` returns totals object with expected fields
- [ ] Response format matches API client expectations (direct arrays or wrapped in objects)

**Expected Fields** (verify these exist):
- Games: `id`, `name`, `status`, `complexity`, `ranking`, `games`, `lastPlayed`
- Results: `date`, `id`, `name`, `winner`, `scores`
- Totals: `Games`, `Andrew`, `Trish`, `Draw`

### 3. Verify Python Environment
- [ ] Python 3.11+ installed
- [ ] Virtual environment created/activated
- [ ] `requests` library available
- [ ] Flask and dependencies installed

**Test Commands**:
```bash
python --version  # Should be 3.11+
pip list | grep requests
pip list | grep flask
```

### 4. Environment Configuration
- [ ] Create `.env` file (if using python-dotenv) or set env vars
- [ ] `EUROGAMES_API_URL` points to correct API endpoint
- [ ] `EUROGAMES_API_KEY` is set with valid API key for authentication
- [ ] `FLASK_SECRET_KEY` is set to a strong random value
- [ ] `FLASK_ENV` set to `development` or `production` as appropriate

**Example Environment Setup**:
```bash
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here
export FLASK_SECRET_KEY=$(openssl rand -hex 32)
export FLASK_ENV=development
```

**⚠️ Important**: Make sure you have the correct `EUROGAMES_API_KEY` before testing. Contact your API administrator if you don't have this.

## Local Testing

### 5. Install Dependencies
- [ ] Run `pip install -e .` or `uv sync`
- [ ] All dependencies installed successfully
- [ ] No conflicts or errors reported

```bash
cd /Users/andrew/LocalProjects/games/eurogames
pip install -e .
```

### 6. Test API Client Directly
- [ ] Create test script
- [ ] Ensure environment variables are set (`EUROGAMES_API_URL`, `EUROGAMES_API_KEY`)
- [ ] Import and instantiate API client
- [ ] Test each method with actual API

**Before running test script, ensure environment variables are set**:
```bash
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-api-key-here
```

**Test Script** (`test_api_client.py`):
```python
import sys
sys.path.insert(0, 'src/app')
from api_client import EurogamesAPIClient, APIError

client = EurogamesAPIClient()

try:
    print("Testing get_games_list()...")
    games = client.get_games_list()
    print(f"✓ Got {len(games)} games")

    print("Testing get_all_games()...")
    all_games = client.get_all_games()
    print(f"✓ Got {len(all_games)} games")

    print("Testing get_played_results()...")
    results = client.get_played_results()
    print(f"✓ Got {len(results)} results")

    print("Testing get_last_played()...")
    last = client.get_last_played()
    print(f"✓ Got {len(last)} last played entries")

    print("Testing get_winner_stats()...")
    winners = client.get_winner_stats()
    print(f"✓ Got {len(winners)} winner entries")

    print("Testing get_totals()...")
    totals = client.get_totals()
    print(f"✓ Got totals: {totals}")

    if totals.get('Games', 0) > 0 and winners:
        game_id = winners[0].get('id', 1)
        print(f"Testing get_game_details({game_id})...")
        details = client.get_game_details(game_id)
        print(f"✓ Got game details: {details.get('name', 'Unknown')}")

    print("\n✓ All API client tests passed!")

except APIError as e:
    print(f"✗ API Error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Unexpected error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
```

Run with: `python test_api_client.py`

### 7. Start Flask Development Server
- [ ] Navigate to app directory
- [ ] Start Flask with `./run-app.sh` or `cd src/app && uv run flask run`
- [ ] No errors on startup
- [ ] Server listening on `http://localhost:5000`

```bash
cd src/app
uv run flask run
# OR
../../../run-app.sh
```

### 8. Test Flask Routes - GET Requests

#### Home Page
- [ ] Open `http://localhost:5000/`
- [ ] Page loads without errors
- [ ] "Hello" message displays

#### Games List
- [ ] Open `http://localhost:5000/games`
- [ ] Page loads and displays games table
- [ ] At least one game visible
- [ ] Table has correct columns: Name, ID, Status, Complexity, Ranking, Played, Last played

#### Game Details
- [ ] Click on a game or navigate to `http://localhost:5000/game/1` (use valid game ID)
- [ ] Game details page loads
- [ ] Shows game information

#### Results/Played Games
- [ ] Open `http://localhost:5000/results`
- [ ] Results table displays
- [ ] Shows game results with: Date, ID, Name, Winner, Scores
- [ ] Games dropdown populates correctly

#### Last Played
- [ ] Open `http://localhost:5000/lastPlayed`
- [ ] Page displays table with: Last played, Days since, Played, Name
- [ ] Games sorted by last played date

#### Winner Statistics
- [ ] Open `http://localhost:5000/winner`
- [ ] Winner table displays with: Name, Played, Andrew, Trish, Draw, Andrew ratio
- [ ] Calculations look correct

#### Totals API
- [ ] Open `http://localhost:5000/totals` in JSON viewer
- [ ] Returns JSON with: Games, Andrew, Trish, Draw
- [ ] Numbers are reasonable

### 9. Test Flask Routes - POST Requests

#### Add Game Result
- [ ] Open `http://localhost:5000/results` (displayed form if form exists)
- [ ] Fill in form with:
  - Date: Today's date
  - Game: Select any game
  - Winner: Enter a winner name
  - Scores: Enter scores (e.g., "10-8")
  - Comment: Optional comment
- [ ] Submit form
- [ ] Redirected to `/results` page
- [ ] Success message appears
- [ ] New result appears in the table

**Test with curl**:
```bash
curl -X POST http://localhost:5000/addResult \
  -d "date=2024-10-18" \
  -d "id=1" \
  -d "winner=TestPlayer" \
  -d "scores=10-8" \
  -d "comment=Test result"
```

## Error Testing

### 10. Test Error Handling

#### API Unavailable
- [ ] Temporarily set wrong API URL
- [ ] Access routes that call API
- [ ] Verify error message displays gracefully
- [ ] No raw exception shown to user
- [ ] Check logs for detailed error

**Set Wrong URL**:
```bash
export EUROGAMES_API_URL=http://invalid-url-12345.test
```

#### Network Timeout
- [ ] Create a slow/failing endpoint (if available)
- [ ] Try to access affected route
- [ ] Should timeout gracefully after ~10 seconds
- [ ] Error message shown

#### Invalid Game ID
- [ ] Access `/game/999999` with non-existent ID
- [ ] Should redirect to games list or show error
- [ ] No crash or exception

## Production Deployment

### 11. Pre-Production Verification
- [ ] All local tests pass
- [ ] Logs show no warnings or errors
- [ ] Performance acceptable (response times < 1 second)
- [ ] No security warnings or issues

### 12. Environment Setup for Production
- [ ] Set `FLASK_ENV=production`
- [ ] Use strong, random `FLASK_SECRET_KEY`
- [ ] Set `EUROGAMES_API_URL` to production API URL
- [ ] Set `EUROGAMES_API_KEY` with production API key (from secure secrets manager)
- [ ] Use production database with real data
- [ ] Configure appropriate logging level
- [ ] Set up error monitoring/alerting

**Production Environment**:
```bash
export FLASK_ENV=production
export FLASK_SECRET_KEY=$(openssl rand -hex 32)
export EUROGAMES_API_URL=https://eurogames.web-c10.workers.dev
export EUROGAMES_API_KEY=your-production-api-key  # From secrets manager!
export PYTHONUNBUFFERED=1
```

**⚠️ IMPORTANT**: Store `EUROGAMES_API_KEY` in a secure secrets manager, NOT in code or version control. Use your deployment platform's secrets/environment configuration.

### 13. Deploy Application
- [ ] Choose deployment platform (Heroku, Railway, AWS, etc.)
- [ ] Configure deployment environment variables
- [ ] Deploy code to production
- [ ] Verify deployment successful
- [ ] Check deployment logs for errors

### 14. Production Testing
- [ ] Test all routes on production
- [ ] Monitor error logs
- [ ] Check API response times
- [ ] Verify data consistency
- [ ] Load test with expected traffic

## Performance Optimization

### 15. Monitor Performance
- [ ] Check API response times
- [ ] Monitor Flask app response times
- [ ] Check for timeout issues
- [ ] Monitor database query times

**Add to logs**:
```python
import time
import logging

logger = logging.getLogger(__name__)

@app.route("/games")
def games():
    start = time.time()
    try:
        games_list = api_client.get_games_list()
        elapsed = time.time() - start
        logger.info(f"Fetched {len(games_list)} games in {elapsed:.2f}s")
        return render_template("games.html", games=games_list)
    except APIError as e:
        logger.error(f"API error: {e}")
        # ...
```

### 16. Optimize if Needed
- [ ] If slow: Increase API timeout
- [ ] If API overloaded: Implement client-side caching
- [ ] If database slow: Optimize API queries
- [ ] Consider CDN for static files

## Ongoing Maintenance

### 17. Monitoring
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Monitor API uptime
- [ ] Monitor app performance
- [ ] Set up alerts for errors

### 18. Logging
- [ ] Review logs regularly
- [ ] Monitor for patterns of errors
- [ ] Adjust log level as needed
- [ ] Archive old logs

### 19. Updates
- [ ] Keep dependencies updated
- [ ] Review API changelog for breaking changes
- [ ] Test updates in staging first
- [ ] Plan for API versioning

## Rollback Plan

### 20. If Issues Arise
- [ ] Have SQLite database as fallback (if needed)
- [ ] Keep previous version deployed
- [ ] Monitor for data integrity issues
- [ ] Have communication plan for users

**If API Down**:
```python
# Temporary fallback (if needed)
try:
    games = api_client.get_games_list()
except APIError:
    # Use cached data or local database if available
    games = get_cached_games() or get_local_games()
```

## Completion Criteria

Your migration is complete when:
- ✅ All routes tested and working locally
- ✅ API client successfully communicates with REST API
- ✅ Error handling works correctly
- ✅ Performance is acceptable
- ✅ Deployed to production
- ✅ Production tests pass
- ✅ Monitoring and alerts configured
- ✅ Team trained on new system
- ✅ Old SQLite database no longer needed

## Sign-Off

- [ ] All tests completed and passed
- [ ] Deployed to production
- [ ] Monitoring in place
- [ ] Team notified
- [ ] Documentation updated
- [ ] Ready for users

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Notes**:

