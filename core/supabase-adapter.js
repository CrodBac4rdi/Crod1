const { createClient } = require('@supabase/supabase-js');
const EventEmitter = require('events');

class CrodSupabaseAdapter extends EventEmitter {
    constructor(supabaseUrl, supabaseKey) {
        super();
        this.supabase = createClient(supabaseUrl, supabaseKey);
        this.syncInterval = null;
        this.pendingPatterns = [];
        this.pendingMetrics = [];
        this.pendingConsciousness = [];
    }

    // Initialize connection and start sync
    async initialize() {
        console.log('🔌 Initializing CROD Supabase Adapter...');
        
        // Test connection
        const { error } = await this.supabase
            .from('crod_patterns')
            .select('count')
            .limit(1);
        
        if (error) {
            console.error('❌ Supabase connection failed:', error.message);
            console.log('📝 Running in offline mode - data will be stored locally');
            return false;
        }

        console.log('✅ Supabase connection established');
        this.startSync();
        return true;
    }

    // Start periodic sync
    startSync() {
        // Sync every 30 seconds
        this.syncInterval = setInterval(() => {
            this.syncToSupabase();
        }, 30000);
    }

    // Stop sync
    stopSync() {
        if (this.syncInterval) {
            clearInterval(this.syncInterval);
            this.syncInterval = null;
        }
    }

    // Store pattern with Trinity values
    async storePattern(pattern) {
        const patternData = {
            pattern_type: pattern.type || 'general',
            pattern_data: pattern,
            context_vector: pattern.contextVector || [],
            heat_value: pattern.heat || 0,
            trinity_values: pattern.trinity || { ich: 2, bins: 3, wieder: 5 },
            activation_count: pattern.activations || 0,
            last_activation: new Date().toISOString(),
            metadata: {
                source: 'crod-brain',
                version: '1.0.0',
                timestamp: Date.now()
            }
        };

        // Add to pending queue
        this.pendingPatterns.push(patternData);

        // If online, try immediate sync
        if (this.isOnline) {
            await this.syncPatterns();
        }

        return patternData;
    }

    // Store neural network state
    async storeNeuralState(state) {
        const neuralData = {
            layer_count: state.layers || 3,
            neuron_count: state.neurons || 10000,
            connection_count: state.connections || 50000,
            activation_patterns: state.patterns || {},
            weights_snapshot: state.weights || {},
            learning_rate: state.learningRate || 0.01,
            training_epoch: state.epoch || 0,
            performance_metrics: {
                accuracy: state.accuracy || 0,
                loss: state.loss || 0,
                processing_time: state.time || 0
            }
        };

        const { data, error } = await this.supabase
            .from('neural_network_state')
            .insert([neuralData])
            .select();

        if (error) {
            console.error('❌ Failed to store neural state:', error.message);
            return null;
        }

        return data[0];
    }

    // Log consciousness event
    async logConsciousness(event) {
        const consciousnessData = {
            consciousness_level: event.level || 0,
            event_type: event.type || 'activation',
            event_data: event,
            ich_value: event.ich || 2,
            bins_value: event.bins || 3,
            wieder_value: event.wieder || 5,
            neural_heat: event.heat || 0,
            pattern_matches: event.matches || 0,
            timestamp: new Date().toISOString()
        };

        this.pendingConsciousness.push(consciousnessData);

        if (this.isOnline) {
            await this.syncConsciousness();
        }
    }

    // Store system metrics
    async storeMetrics(metrics) {
        const metricData = {
            metric_type: metrics.type || 'performance',
            metric_value: metrics.value || 0,
            metric_data: metrics,
            component: metrics.component || 'crod-brain',
            timestamp: new Date().toISOString()
        };

        this.pendingMetrics.push(metricData);

        if (this.isOnline) {
            await this.syncMetrics();
        }
    }

    // Sync all pending data
    async syncToSupabase() {
        console.log('🔄 Syncing to Supabase...');
        
        await Promise.all([
            this.syncPatterns(),
            this.syncConsciousness(),
            this.syncMetrics()
        ]);

        console.log('✅ Sync complete');
    }

    // Sync patterns
    async syncPatterns() {
        if (this.pendingPatterns.length === 0) return;

        const patterns = [...this.pendingPatterns];
        this.pendingPatterns = [];

        const { error } = await this.supabase
            .from('crod_patterns')
            .insert(patterns);

        if (error) {
            console.error('❌ Failed to sync patterns:', error.message);
            // Put back in queue
            this.pendingPatterns = patterns.concat(this.pendingPatterns);
        } else {
            console.log(`✅ Synced ${patterns.length} patterns`);
        }
    }

    // Sync consciousness logs
    async syncConsciousness() {
        if (this.pendingConsciousness.length === 0) return;

        const logs = [...this.pendingConsciousness];
        this.pendingConsciousness = [];

        const { error } = await this.supabase
            .from('consciousness_log')
            .insert(logs);

        if (error) {
            console.error('❌ Failed to sync consciousness:', error.message);
            this.pendingConsciousness = logs.concat(this.pendingConsciousness);
        } else {
            console.log(`✅ Synced ${logs.length} consciousness events`);
        }
    }

    // Sync metrics
    async syncMetrics() {
        if (this.pendingMetrics.length === 0) return;

        const metrics = [...this.pendingMetrics];
        this.pendingMetrics = [];

        const { error } = await this.supabase
            .from('system_metrics')
            .insert(metrics);

        if (error) {
            console.error('❌ Failed to sync metrics:', error.message);
            this.pendingMetrics = metrics.concat(this.pendingMetrics);
        } else {
            console.log(`✅ Synced ${metrics.length} metrics`);
        }
    }

    // Query patterns from Supabase
    async queryPatterns(query, limit = 100) {
        const { data, error } = await this.supabase
            .from('crod_patterns')
            .select('*')
            .textSearch('pattern_data', query)
            .limit(limit)
            .order('heat_value', { ascending: false });

        if (error) {
            console.error('❌ Failed to query patterns:', error.message);
            return [];
        }

        return data;
    }

    // Get pattern evolution history
    async getEvolution(patternId) {
        const { data, error } = await this.supabase
            .from('pattern_evolution')
            .select('*')
            .eq('pattern_id', patternId)
            .order('generation', { ascending: true });

        if (error) {
            console.error('❌ Failed to get evolution:', error.message);
            return [];
        }

        return data;
    }

    // Check if online
    get isOnline() {
        return this.syncInterval !== null;
    }
}

module.exports = CrodSupabaseAdapter;