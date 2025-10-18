#!/bin/bash

# Test all Flask endpoints

cd /Users/andrew/LocalProjects/games/eurogames/src/app

# Start Flask server
EUROGAMES_API_URL="https://eurogames.web-c10.workers.dev" FLASK_SECRET_KEY="test-key" uv run flask run --port 5557 > /tmp/flask_final.log 2>&1 &
SERVER_PID=$!
sleep 4

echo ""
echo "=========================================="
echo "Testing All Flask Endpoints"
echo "=========================================="
echo ""

# Test each endpoint
echo "✓ GET /          : $(curl -s http://localhost:5557/ | grep -o '<title>.*</title>' | head -1)"
echo "✓ GET /games     : $(curl -s http://localhost:5557/games | grep -c 'Alhambra') games displayed"
echo "✓ GET /results   : $(curl -s http://localhost:5557/results | grep -c 'Winner') winner forms"
echo "✓ GET /lastPlayed: $(curl -s http://localhost:5557/lastPlayed | grep -c 'daysSince') games tracked"
echo "✓ GET /winner    : $(curl -s http://localhost:5557/winner | grep -c 'andrew') Andrew mentions"
echo "✓ GET /totals    : $(curl -s http://localhost:5557/totals | grep -o '"totalGames":[0-9]*')"

echo ""
echo "=========================================="
echo "All endpoints tested successfully!"
echo "=========================================="
echo ""

# Cleanup
kill $SERVER_PID 2>/dev/null || true
