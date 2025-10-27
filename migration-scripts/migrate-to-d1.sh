#!/bin/bash

# Migrate Eurogames SQLite database to Cloudflare D1
# This script handles the complete migration process

set -e

echo "🎯 Starting Eurogames D1 Migration"
echo "=================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Please install it first:"
    echo "   npm install -g wrangler"
    exit 1
fi

# Check if database file exists
if [ ! -f "data/games.db" ]; then
    echo "❌ SQLite database not found at data/games.db"
    exit 1
fi

# Step 1: Export data from SQLite
echo "📦 Step 1: Exporting data from SQLite..."
if [ ! -f "scripts/export-to-d1.js" ]; then
    echo "❌ Export script not found. Please ensure scripts/export-to-d1.js exists."
    exit 1
fi

# Install node dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📋 Installing Node.js dependencies..."
    npm install sqlite3
fi

node scripts/export-to-d1.js

# Step 2: Create D1 database schema
echo "🏗️  Step 2: Creating D1 database schema..."
wrangler d1 execute games --remote --file=migrations/0001_initial_schema.sql

echo "🔍 Step 3: Creating database views..."
wrangler d1 execute games --remote --file=migrations/0002_create_views.sql

# Step 4: Import data
echo "📥 Step 4: Importing data to D1..."

if [ -f "migrations/data/bgg.sql" ]; then
    echo "   Importing BGG game data..."
    wrangler d1 execute games --remote --file=migrations/data/bgg.sql
fi

if [ -f "migrations/data/notes.sql" ]; then
    echo "   Importing game notes..."
    wrangler d1 execute games --remote --file=migrations/data/notes.sql
fi

if [ -f "migrations/data/log.sql" ]; then
    echo "   Importing game play log..."
    wrangler d1 execute games --remote --file=migrations/data/log.sql
fi

if [ -f "migrations/data/saved_queries.sql" ]; then
    echo "   Importing saved queries..."
    wrangler d1 execute games --remote --file=migrations/data/saved_queries.sql
fi

# Step 5: Verify migration
echo "✅ Step 5: Verifying migration..."
echo "Checking table counts:"

wrangler d1 execute games --remote --command="SELECT 'bgg' as table_name, COUNT(*) as count FROM bgg 
UNION ALL SELECT 'notes' as table_name, COUNT(*) as count FROM notes 
UNION ALL SELECT 'log' as table_name, COUNT(*) as count FROM log;"

echo ""
echo "🎉 Migration completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Test the D1 database with sample queries"
echo "2. Update your application to use D1 instead of SQLite"
echo "3. Deploy your Workers application"
echo ""
echo "🔧 Useful commands:"
echo "   wrangler d1 execute games --remote --command='SELECT COUNT(*) FROM bgg'"
echo "   wrangler dev (to test locally)"
echo "   wrangler deploy (to deploy to production)"