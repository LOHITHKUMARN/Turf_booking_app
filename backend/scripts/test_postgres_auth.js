require('dotenv').config();
const request = require('supertest');

// Set provider to postgres for this test
process.env.DB_PROVIDER = 'postgres';

const app = require('../src/app');

const testAuth = async () => {
    try {
        console.log('Testing Super Admin login against Supabase PostgreSQL...');

        const res = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'admin@turf.com',
                password: 'AdminPassword123!'
            });

        console.log('HTTP Status:', res.status);
        console.log('Response Body:');
        console.log({
            _id: res.body._id,
            id: res.body.id,
            name: res.body.name,
            email: res.body.email,
            role: res.body.role,
            hasAccessToken: !!res.body.token,
            hasRefreshToken: !!res.body.refreshToken
        });

        if (res.status === 200 && res.body.role === 'admin' && res.body._id && res.body.token) {
            console.log('\n✅ SUCCESS: Supabase PostgreSQL authentication is working perfectly!');
            process.exit(0);
        } else {
            console.error('\n❌ FAILED: Unexpected response', res.body);
            process.exit(1);
        }
    } catch (err) {
        console.error('Test error:', err);
        process.exit(1);
    }
};

testAuth();
