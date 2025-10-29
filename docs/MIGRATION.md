# D1 Migration Guide

This guide walks through migrating your local SQLite Eurogames database to Cloudflare D1.

## Prerequisites

1. **Wrangler CLI** installed and authenticated:
   ```bash
   npm install -g wrangler
   wrangler auth login
   ```

2. **Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Local SQLite database** at `data/games.db`

## Migration Process

### Option 1: Automated Migration (Recommended)

Run the complete migration script:
```bash
./scripts/migrate-to-d1.sh
```

This script will:
- Export data from SQLite to SQL files
- Create D1 database schema
- Import all data to D1
- Verify the migration

### Option 2: Manual Step-by-Step Migration

#### Step 1: Export Data
```bash
node scripts/export-to-d1.js
```

#### Step 2: Create Schema
```bash
wrangler d1 execute games --remote --file=migrations/0001_initial_schema.sql
wrangler d1 execute games --remote --file=migrations/0002_create_views.sql
```

#### Step 3: Import Data
```bash
wrangler d1 execute games --remote --file=migrations/data/bgg.sql
wrangler d1 execute games --remote --file=migrations/data/notes.sql  
wrangler d1 execute games --remote --file=migrations/data/log.sql
wrangler d1 execute games --remote --file=migrations/data/saved_queries.sql
```

## Verification

Check the migration was successful:

```bash
# Count records in each table
wrangler d1 execute games --remote --command="
  SELECT 'bgg' as table, COUNT(*) as count FROM bgg 
  UNION ALL 
  SELECT 'notes' as table, COUNT(*) as count FROM notes 
  UNION ALL 
  SELECT 'log' as table, COUNT(*) as count FROM log"

# Test a sample query
wrangler d1 execute games --remote --command="
  SELECT name, status, complexity 
  FROM game_list2 
  WHERE status = 'Playing' 
  LIMIT 5"

# Check views are working
wrangler d1 execute games --remote --command="
  SELECT name, Games, Andrew, Trish 
  FROM winner 
  LIMIT 5"
```

## Local Development

Test queries locally during development:
```bash
wrangler dev
```

## Troubleshooting

### Common Issues

1. **"Database not found" error**:
   - Verify the database ID in `wrangler.toml` matches your D1 database
   - Check you're authenticated: `wrangler auth whoami`

2. **SQL syntax errors**:
   - D1 uses SQLite syntax but may have slight differences
   - Check the migration logs for specific error messages

3. **Large data imports failing**:
   - Split large data files into smaller batches
   - Use the `--batch-size` flag if available

### Manual Rollback

If you need to recreate the D1 database:
```bash
# Delete and recreate (WARNING: destroys all data)
wrangler d1 delete games
wrangler d1 create games
# Then re-run migration
```

### Useful Commands

```bash
# List your D1 databases
wrangler d1 list

# Execute a single command
wrangler d1 execute games --remote --command="SELECT COUNT(*) FROM bgg"

# Backup D1 database (export)
wrangler d1 export games --output=backup.sql

# Get database info
wrangler d1 info games
```

## Next Steps

After successful migration:

1. Update your application code to use D1 instead of direct SQLite
2. Test all functionality with the D1 database  
3. Deploy your Workers application: `wrangler deploy`
4. Update your CLI tools to use the new API endpoints

## File Structure

```
migrations/
├── 0001_initial_schema.sql     # Database tables and indexes
├── 0002_create_views.sql       # Database views
└── data/                       # Exported data files
    ├── bgg.sql
    ├── notes.sql
    ├── log.sql
    └── saved_queries.sql

scripts/
├── export-to-d1.js            # Data export script
└── migrate-to-d1.sh           # Complete migration script
```