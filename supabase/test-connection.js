const { createClient } = require('@supabase/supabase-js');

// Supabase credentials
const supabaseUrl = 'https://nytczkafznwyfxbkzfzv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55dGN6a2Fmem53eWZ4Ymt6Znp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjM1NDEzOSwiZXhwIjoyMDY3OTMwMTM5fQ.Jw_QTb8KObcY2vZdwZLSQZoF1EJfCorNfU7o6vjDOwE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConnection() {
    console.log('🧪 Testing Supabase Connection...\n');

    try {
        // Test 1: Check CROD patterns table
        console.log('📊 Testing crod_patterns table...');
        const { data: patterns, error: patternsError } = await supabase
            .from('crod_patterns')
            .select('*')
            .limit(1);
        
        if (patternsError) {
            console.error('❌ Error accessing crod_patterns:', patternsError.message);
        } else {
            console.log('✅ crod_patterns table accessible');
        }

        // Test 2: Check knowledge graph entities
        console.log('\n📊 Testing knowledge_graph_entities table...');
        const { data: entities, error: entitiesError } = await supabase
            .from('knowledge_graph_entities')
            .select('*')
            .limit(1);
        
        if (entitiesError) {
            console.error('❌ Error accessing knowledge_graph_entities:', entitiesError.message);
        } else {
            console.log('✅ knowledge_graph_entities table accessible');
        }

        // Test 3: Check layered atomic memory
        console.log('\n📊 Testing layered_atomic_base table...');
        const { data: atoms, error: atomsError } = await supabase
            .from('layered_atomic_base')
            .select('*')
            .limit(1);
        
        if (atomsError) {
            console.error('❌ Error accessing layered_atomic_base:', atomsError.message);
        } else {
            console.log('✅ layered_atomic_base table accessible');
        }

        // Test 4: Insert a test pattern
        console.log('\n🧪 Testing data insertion...');
        const testPattern = {
            pattern_type: 'test',
            pattern_data: {
                content: 'Test pattern from Supabase connection test',
                timestamp: new Date().toISOString()
            },
            context_vector: [0.1, 0.2, 0.3],
            heat_value: 0.5,
            trinity_values: { ich: 2, bins: 3, wieder: 5 }
        };

        const { data: insertData, error: insertError } = await supabase
            .from('crod_patterns')
            .insert([testPattern])
            .select();
        
        if (insertError) {
            console.error('❌ Error inserting test pattern:', insertError.message);
        } else {
            console.log('✅ Successfully inserted test pattern with ID:', insertData[0].id);
            
            // Clean up test data
            const { error: deleteError } = await supabase
                .from('crod_patterns')
                .delete()
                .eq('id', insertData[0].id);
            
            if (!deleteError) {
                console.log('🧹 Cleaned up test data');
            }
        }

        // Test 5: Check monitoring tables
        console.log('\n📊 Testing monitoring tables...');
        const { error: metricsError } = await supabase
            .from('system_metrics')
            .select('*')
            .limit(1);
        
        if (metricsError) {
            console.error('❌ Error accessing system_metrics:', metricsError.message);
        } else {
            console.log('✅ system_metrics table accessible');
        }

        console.log('\n✨ Supabase connection test complete!');

    } catch (error) {
        console.error('🚨 Unexpected error:', error);
    }
}

// Run the test
testConnection();