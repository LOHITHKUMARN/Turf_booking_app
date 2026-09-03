const { createClient } = require('@supabase/supabase-js');
const logger = require('../services/logger');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

let supabase = null;

if (supabaseUrl && supabaseKey) {
    try {
        supabase = createClient(supabaseUrl, supabaseKey, {
            auth: {
                persistSession: false,
                autoRefreshToken: false
            }
        });
        logger.info('Supabase Client initialized successfully');
    } catch (err) {
        logger.warn('Failed to initialize Supabase client:', { error: err.message });
    }
} else {
    logger.warn('Supabase credentials (SUPABASE_URL, SUPABASE_ANON_KEY) not found in environment');
}

module.exports = supabase;
