require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');

// Lightweight app for auth tests
const app = express();
app.use(express.json());
app.use('/api/auth', require('../src/routes/auth.routes'));

jest.setTimeout(20000);

let testUser;
const TEST_USER = {
    name: 'Test User',
    email: `testuser_${Date.now()}@test.com`,
    phone: `9${Date.now().toString().slice(-9)}`,
    password: 'testpass123',
};

beforeAll(async () => {
    if (mongoose.connection.readyState === 0) {
        await mongoose.connect(process.env.MONGODB_URI);
    }
});

afterAll(async () => {
    try {
        const User = require('../src/models/User');
        await User.deleteOne({ email: TEST_USER.email });
        await mongoose.connection.close();
    } catch (err) {
        console.error('Teardown error:', err);
    }
});

describe('Auth API', () => {
    describe('POST /api/auth/signup', () => {
        it('should register a new user', async () => {
            const res = await request(app)
                .post('/api/auth/signup')
                .send(TEST_USER);

            expect(res.statusCode).toBe(201);
            expect(res.body).toHaveProperty('token');
            expect(res.body.email).toBe(TEST_USER.email);
            expect(res.body.role).toBe('customer');
        });

        it('should reject duplicate email', async () => {
            const res = await request(app)
                .post('/api/auth/signup')
                .send(TEST_USER);

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('User already exists');
        });

        it('should reject invalid email format', async () => {
            const res = await request(app)
                .post('/api/auth/signup')
                .send({ ...TEST_USER, email: 'not-an-email', phone: '1111111111' });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('Validation failed');
        });

        it('should reject short password', async () => {
            const res = await request(app)
                .post('/api/auth/signup')
                .send({ ...TEST_USER, email: 'short@test.com', phone: '2222222222', password: '12' });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('Validation failed');
        });
    });

    describe('POST /api/auth/login', () => {
        it('should login with valid credentials', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: TEST_USER.email, password: TEST_USER.password });

            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('token');
            expect(res.body.email).toBe(TEST_USER.email);
        });

        it('should reject wrong password', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: TEST_USER.email, password: 'wrongpassword' });

            expect(res.statusCode).toBe(401);
            expect(res.body.message).toBe('Invalid credentials');
        });

        it('should reject non-existent user', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: 'nobody@test.com', password: 'whatever' });

            expect(res.statusCode).toBe(401);
        });
    });
});
