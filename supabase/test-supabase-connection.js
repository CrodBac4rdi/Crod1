#!/usr/bin/env node

const https = require('https');
const { URL } = require('url');

// Supabase credentials
const SUPABASE_URL = 'https://nytczkafznwyfxbkzfzv.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55dGN6a2Fmem53eWZ4Ymt6Znp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjM1NDEzOSwiZXhwIjoyMDY3OTMwMTM5fQ.Jw_QTb8KObcY2vZdwZLSQZoF1EJfCorNfU7o6vjDOwE';

// Test function
async function testSupabaseConnection() {
    console.log('🧪 Testing Supabase Connection...\n');
    
    // Test 1: Insert test consciousness log
    console.log('1️⃣ Testing consciousness_log table...');
    try {
        const testData = {
            consciousness_level: 0.172,
            ich_count: 2,
            bins_count: 3,
            wieder_count: 5,
            neural_activity: 0.05,
            pattern_density: 0.004,
            time_decay: 1.0
        };
        
        const result = await supabaseRequest('/rest/v1/consciousness_log', 'POST', testData);
        console.log('✅ Successfully inserted consciousness log');
    } catch (error) {
        console.error('❌ Failed to insert consciousness log:', error.message);
    }
    
    // Test 2: Insert test knowledge entity
    console.log('\n2️⃣ Testing knowledge_entities table...');
    try {
        const testEntity = {
            name: 'CROD_Supabase_Test_' + Date.now(),
            entity_type: 'Test_Entity',
            observations: ['Supabase connection test', 'Created at ' + new Date().toISOString()]
        };
        
        const result = await supabaseRequest('/rest/v1/knowledge_entities', 'POST', testEntity);
        console.log('✅ Successfully inserted knowledge entity');
    } catch (error) {
        console.error('❌ Failed to insert knowledge entity:', error.message);
    }
    
    // Test 3: Query data back
    console.log('\n3️⃣ Testing data retrieval...');
    try {
        const entities = await supabaseRequest('/rest/v1/knowledge_entities?entity_type=eq.Test_Entity', 'GET');
        console.log(`✅ Found ${entities.length} test entities`);
    } catch (error) {
        console.error('❌ Failed to retrieve data:', error.message);
    }
    
    // Test 4: Test system health table
    console.log('\n4️⃣ Testing system_health table...');
    try {
        const healthData = {
            service_name: 'crod-test-service',
            health_status: 'healthy',
            metrics: {
                test_time: Date.now(),
                supabase_connected: true
            }
        };
        
        await supabaseRequest('/rest/v1/system_health', 'POST', healthData);
        console.log('✅ Successfully logged system health');
    } catch (error) {
        console.error('❌ Failed to log system health:', error.message);
    }
    
    console.log('\n✨ Supabase connection test complete!');
}

// Helper function for Supabase requests
function supabaseRequest(path, method, data) {
    return new Promise((resolve, reject) => {
        const url = new URL(SUPABASE_URL + path);
        
        const options = {
            method: method,
            headers: {
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            }
        };
        
        const req = https.request(url, options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(body));
                    } catch {
                        resolve(body);
                    }
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });
        
        req.on('error', reject);
        
        if (data && method !== 'GET') {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

// Run the test
testSupabaseConnection().catch(console.error);