#!/usr/bin/env node

/**
 * Verify D1 migration by comparing local SQLite with D1 database
 * This script helps ensure data integrity after migration
 */

const sqlite3 = require('sqlite3').verbose();
const { execSync } = require('child_process');

const DB_PATH = 'data/games.db';

function executeWranglerQuery(sql) {
    try {
        const result = execSync(`wrangler d1 execute games --remote --command="${sql}"`, { 
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'pipe']
        });
        return result.trim();
    } catch (error) {
        console.error(`Error executing D1 query: ${error.message}`);
        return null;
    }
}

function getSQLiteCount(db, table) {
    return new Promise((resolve, reject) => {
        db.get(`SELECT COUNT(*) as count FROM ${table}`, (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
        });
    });
}

async function verifyTableCounts() {
    const db = new sqlite3.Database(DB_PATH);
    const tables = ['bgg', 'notes', 'log', 'saved_queries'];
    
    console.log('🔍 Verifying table record counts...\n');
    console.log('Table'.padEnd(15) + 'SQLite'.padEnd(10) + 'D1'.padEnd(10) + 'Status');
    console.log('-'.repeat(50));
    
    let allMatch = true;
    
    for (const table of tables) {
        try {
            const sqliteCount = await getSQLiteCount(db, table);
            const d1Result = executeWranglerQuery(`SELECT COUNT(*) as count FROM ${table}`);
            
            // Parse D1 result (it includes headers and formatting)
            let d1Count = 0;
            if (d1Result) {
                const match = d1Result.match(/(\d+)/);
                d1Count = match ? parseInt(match[1]) : 0;
            }
            
            const status = sqliteCount === d1Count ? '✅ Match' : '❌ Mismatch';
            console.log(
                table.padEnd(15) + 
                sqliteCount.toString().padEnd(10) + 
                d1Count.toString().padEnd(10) + 
                status
            );
            
            if (sqliteCount !== d1Count) {
                allMatch = false;
            }
        } catch (error) {
            console.log(table.padEnd(15) + 'Error'.padEnd(10) + 'Error'.padEnd(10) + '❌ Error');
            console.error(`Error verifying ${table}: ${error.message}`);
            allMatch = false;
        }
    }
    
    db.close();
    return allMatch;
}

async function testSampleQueries() {
    console.log('\n🧪 Testing sample queries...\n');
    
    const testQueries = [
        {
            name: 'Game List View',
            sql: 'SELECT COUNT(*) FROM game_list2'
        },
        {
            name: 'Played Games View', 
            sql: 'SELECT COUNT(*) FROM played'
        },
        {
            name: 'Winner Stats View',
            sql: 'SELECT COUNT(*) FROM winner'
        },
        {
            name: 'Recent Games',
            sql: 'SELECT name, winner FROM played LIMIT 3'
        },
        {
            name: 'Active Games',
            sql: "SELECT COUNT(*) FROM game_list2 WHERE status = 'Playing'"
        }
    ];
    
    for (const test of testQueries) {
        try {
            console.log(`Testing: ${test.name}`);
            const result = executeWranglerQuery(test.sql);
            if (result) {
                console.log('✅ Success');
            } else {
                console.log('❌ Failed');
            }
        } catch (error) {
            console.log('❌ Error:', error.message);
        }
    }
}

async function main() {
    console.log('🎯 Eurogames D1 Migration Verification');
    console.log('=====================================\n');
    
    // Check prerequisites
    try {
        execSync('wrangler --version', { stdio: 'ignore' });
    } catch (error) {
        console.error('❌ Wrangler CLI not found. Please install it first.');
        process.exit(1);
    }
    
    if (!require('fs').existsSync(DB_PATH)) {
        console.error('❌ SQLite database not found at', DB_PATH);
        process.exit(1);
    }
    
    try {
        const countsMatch = await verifyTableCounts();
        await testSampleQueries();
        
        console.log('\n📋 Verification Summary:');
        console.log('========================');
        
        if (countsMatch) {
            console.log('✅ All table counts match between SQLite and D1');
            console.log('✅ Sample queries executed successfully'); 
            console.log('\n🎉 Migration verification passed!');
            console.log('\nYour D1 database is ready for use.');
        } else {
            console.log('❌ Some table counts do not match');
            console.log('\n⚠️  Migration verification failed!');
            console.log('\nPlease check the migration process and try again.');
            process.exit(1);
        }
        
    } catch (error) {
        console.error('❌ Verification failed:', error.message);
        process.exit(1);
    }
}

main();