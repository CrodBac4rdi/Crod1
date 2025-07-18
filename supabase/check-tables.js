const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://nytczkafznwyfxbkzfzv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55dGN6a2Fmem53eWZ4Ymt6Znp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjM1NDEzOSwiZXhwIjoyMDY3OTMwMTM5fQ.Jw_QTb8KObcY2vZdwZLSQZoF1EJfCorNfU7o6vjDOwE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTables() {
    console.log('🔍 Checking existing tables in Supabase...\n');

    try {
        // Query the information schema to list all tables
        const { data, error } = await supabase
            .rpc('get_tables_list', {})
            .select('*');

        if (error) {
            // Try a different approach - query pg_tables
            const { data: pgTables, error: pgError } = await supabase
                .from('pg_tables')
                .select('tablename')
                .eq('schemaname', 'public');
            
            if (pgError) {
                console.log('❌ Cannot query tables directly. Let me try another method...');
                
                // Try to query known Supabase system tables
                const { data: authData, error: authError } = await supabase
                    .from('auth.users')
                    .select('count');
                
                if (!authError) {
                    console.log('✅ Auth schema exists');
                }

                // Just try to create a simple test table
                console.log('\n🧪 Creating a test table to verify permissions...');
                const { error: createError } = await supabase.rpc('query', {
                    query: `
                        CREATE TABLE IF NOT EXISTS test_connection (
                            id SERIAL PRIMARY KEY,
                            test_data TEXT,
                            created_at TIMESTAMPTZ DEFAULT NOW()
                        )
                    `
                });

                if (createError) {
                    console.log('❌ Cannot create tables via RPC:', createError.message);
                    console.log('\n📝 Tables need to be created via Supabase Dashboard SQL Editor');
                    console.log('Please run the SQL files in the Supabase Dashboard:\n');
                    console.log('1. Go to https://supabase.com/dashboard/project/nytczkafznwyfxbkzfzv/sql');
                    console.log('2. Copy and paste each SQL file from supabase/schemas/');
                    console.log('3. Execute them in order: 01, 02, 03, 04, 05');
                }
            } else {
                console.log('📋 Public tables found:');
                pgTables.forEach(table => {
                    console.log(`  - ${table.tablename}`);
                });
            }
        } else {
            console.log('📋 Tables found:', data);
        }

    } catch (error) {
        console.error('🚨 Error checking tables:', error.message);
    }
}

checkTables();