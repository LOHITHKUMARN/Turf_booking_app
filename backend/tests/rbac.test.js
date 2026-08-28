require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');

const User = require('../src/models/User');

// Lightweight app for RBAC tests
const app = express();
app.use(express.json());
app.use('/api/auth', require('../src/routes/auth.routes'));
app.use('/api/owner', require('../src/routes/owner.routes'));
app.use('/api/admin', require('../src/routes/admin.routes'));

jest.setTimeout(20000);

let customerToken, ownerToken;

const CUSTOMER_EMAIL = `rbac_cust_${Date.now()}@test.com`;
const CUSTOMER_PHONE = `7${Date.now().toString().slice(-9)}`;
const OWNER_EMAIL = `rbac_owner_${Date.now()}@test.com`;
const OWNER_PHONE = `6${Date.now().toString().slice(-9)}`;

beforeAll(async () => {
    if (mongoose.connection.readyState === 0) {
        await mongoose.connect(process.env.MONGODB_URI);
    }

    // Create customer
    const custRes = await request(app)
        .post('/api/auth/signup')
        .send({ name: 'RBAC Customer', email: CUSTOMER_EMAIL, phone: CUSTOMER_PHONE, password: 'test123456' });
    customerToken = custRes.body.token;

    // Create owner
    const ownerRes = await request(app)
        .post('/api/auth/signup')
        .send({ name: 'RBAC Owner', email: OWNER_EMAIL, phone: OWNER_PHONE, password: 'test123456', role: 'owner' });
    ownerToken = ownerRes.body.token;
});

afterAll(async () => {
    try {
        await User.deleteOne({ email: CUSTOMER_EMAIL });
        await User.deleteOne({ email: OWNER_EMAIL });
        await mongoose.connection.close();
    } catch (err) {
        console.error('Teardown error:', err);
    }
});

describe('Role-Based Access Control (RBAC)', () => {
    describe('Owner routes', () => {
        it('should allow owner to access /api/owner/turfs', async () => {
            const res = await request(app)
                .get('/api/owner/turfs')
                .set('Authorization', `Bearer ${ownerToken}`);

            expect(res.statusCode).toBe(200);
        });

        it('should DENY customer from accessing /api/owner/turfs', async () => {
            const res = await request(app)
                .get('/api/owner/turfs')
                .set('Authorization', `Bearer ${customerToken}`);

            expect(res.statusCode).toBe(403);
        });

        it('should DENY unauthenticated access to /api/owner/turfs', async () => {
            const res = await request(app)
                .get('/api/owner/turfs');

            expect(res.statusCode).toBe(401);
        });
    });

    describe('Admin routes', () => {
        it('should DENY owner from accessing /api/admin/stats', async () => {
            const res = await request(app)
                .get('/api/admin/stats')
                .set('Authorization', `Bearer ${ownerToken}`);

            expect(res.statusCode).toBe(403);
        });

        it('should DENY customer from accessing /api/admin/users', async () => {
            const res = await request(app)
                .get('/api/admin/users')
                .set('Authorization', `Bearer ${customerToken}`);

            expect(res.statusCode).toBe(403);
        });
    });
});
