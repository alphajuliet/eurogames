#!/bin/bash

cd /Users/andrew/LocalProjects/games/eurogames/src/app

# Start Flask
EUROGAMES_API_URL="https://eurogames.web-c10.workers.dev" FLASK_SECRET_KEY="test-key" uv run flask run --port 5560 > /tmp/flask_test3.log 2>&1 &
PID=$!
sleep 4

echo ""
echo "Testing Flask /games endpoint with updated get_games_list()"
echo "==========================================================="
echo ""

# Get games page
RESPONSE=$(curl -s http://localhost:5560/games)

# Count games
GAME_COUNT=$(echo "$RESPONSE" | grep -c '<td class="link" hx-get="/game/')
echo "Games displayed on /games page: $GAME_COUNT"

# Show some sample games
echo ""
echo "Sample games from /games page:"
echo "$RESPONSE" | grep -o '<td class="link" hx-get="/game/[0-9]*">[^<]*</td>' | head -5 | sed 's/<[^>]*>//g' | awk '{print "  - " $0}'

echo ""
echo "✓ Flask /games endpoint working correctly"
echo ""

# Cleanup
kill $PID 2>/dev/null || true
