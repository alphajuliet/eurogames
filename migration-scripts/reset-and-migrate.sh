#!/bin/bash

# Reset D1 database and migrate fresh data from local SQLite
# This script clears all data from D1 and uploads the latest local data

set -e

echo "🗑️  Clearing remote D1 database..."
echo "=================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Please install it first:"
    echo "   npm install -g wrangler"
    exit 1
fi

# Clear all data from tables (preserves schema)
echo "Deleting data from all tables..."
wrangler d1 execute games --remote --command="DELETE FROM log; DELETE FROM notes; DELETE FROM saved_queries; DELETE FROM bgg;"

echo "✅ Remote database cleared"
echo ""

# Run the migration to upload fresh data
echo "📤 Uploading fresh data from local database..."
echo "=================================="
./scripts/migrate-to-d1.sh

echo ""
echo "🎉 Reset and migration completed!"
echo ""
echo "🔍 To verify the data, run:"
echo "   wrangler d1 execute games --remote --command='SELECT COUNT(*) FROM bgg'"
