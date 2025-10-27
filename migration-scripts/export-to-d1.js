#!/usr/bin/env node

/**
 * Export SQLite data to D1-compatible SQL format
 * Generates INSERT statements for migration to Cloudflare D1
 */

const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const DB_PATH = 'data/games.db';
const OUTPUT_DIR = 'migrations/data';

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function escapeValue(value) {
    if (value === null || value === undefined) {
        return 'NULL';
    }
    if (typeof value === 'string') {
        return `'${value.replace(/'/g, "''")}'`;
    }
    return value;
}

function generateInserts(tableName, rows) {
    if (rows.length === 0) return '';
    
    const columns = Object.keys(rows[0]);
    const columnList = columns.map(col => `[${col}]`).join(', ');
    
    let sql = `-- Data for table: ${tableName}\n`;
    
    for (const row of rows) {
        const values = columns.map(col => escapeValue(row[col])).join(', ');
        sql += `INSERT INTO "${tableName}" (${columnList}) VALUES (${values});\n`;
    }
    
    return sql + '\n';
}

async function exportTable(db, tableName) {
    return new Promise((resolve, reject) => {
        db.all(`SELECT * FROM ${tableName}`, (err, rows) => {
            if (err) {
                reject(err);
                return;
            }
            
            const sql = generateInserts(tableName, rows);
            const filename = path.join(OUTPUT_DIR, `${tableName}.sql`);
            
            fs.writeFileSync(filename, sql);
            console.log(`Exported ${rows.length} rows from ${tableName} to ${filename}`);
            resolve();
        });
    });
}

async function main() {
    const db = new sqlite3.Database(DB_PATH);
    
    try {
        console.log('Exporting data from SQLite to D1 format...');
        
        // Export core tables
        await exportTable(db, 'bgg');
        await exportTable(db, 'notes'); 
        await exportTable(db, 'log');
        await exportTable(db, 'saved_queries');
        
        console.log('Export completed successfully!');
        console.log('\nNext steps:');
        console.log('1. Run: wrangler d1 execute games --remote --file=migrations/0001_initial_schema.sql');
        console.log('2. Run: wrangler d1 execute games --remote --file=migrations/0002_create_views.sql');
        console.log('3. Run data imports:');
        console.log('   wrangler d1 execute games --remote --file=migrations/data/bgg.sql');
        console.log('   wrangler d1 execute games --remote --file=migrations/data/notes.sql');
        console.log('   wrangler d1 execute games --remote --file=migrations/data/log.sql');
        console.log('   wrangler d1 execute games --remote --file=migrations/data/saved_queries.sql');
        
    } catch (error) {
        console.error('Export failed:', error);
        process.exit(1);
    } finally {
        db.close();
    }
}

main();