require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../src/models/User');
const Turf = require('../src/models/Turf');
const Slot = require('../src/models/Slot');
const Booking = require('../src/models/Booking');

// Lightweight app for booking tests
const app = express();
app.use(express.json());
app.use('/api/auth', require('../src/routes/auth.routes'));
app.use('/api/customer', require('../src/routes/customer.routes'));

jest.setTimeout(20000);

let testUser, token, testTurf, testSlot;

const TEST_EMAIL = `booking_test_${Date.now()}@test.com`;
const TEST_PHONE = `8${Date.now().toString().slice(-9)}`;

beforeAll(async () => {
    if (mongoose.connection.readyState === 0) {
        await mongoose.connect(process.env.MONGODB_URI);
    }

    // Create test user
    const res = await request(app)
        .post('/api/auth/signup')
        .send({ name: 'Booking Tester', email: TEST_EMAIL, phone: TEST_PHONE, password: 'booktest123' });
    token = res.body.token;
    testUser = res.body;

    // Create test turf directly in DB
    testTurf = await Turf.create({
        ownerId: new mongoose.Types.ObjectId(),
        name: 'Test Turf for Booking',
        location: { city: 'TestCity', area: 'TestArea' },
        sports: ['Football'],
        amenities: ['Parking'],
        status: 'approved',
        turfType: 'outdoor',
    });

    // Create test slot
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const dayOfWeek = days[tomorrow.getDay()];

    testSlot = await Slot.create({
        turfId: testTurf._id,
        sport: 'Football',
        dayOfWeek,
        startTime: '10:00',
        endTime: '11:00',
        price: 500,
    });
});

afterAll(async () => {
    try {
        // Cleanup
        await User.deleteOne({ email: TEST_EMAIL });
        await Booking.deleteMany({ turfId: testTurf._id });
        await Slot.deleteOne({ _id: testSlot._id });
        await Turf.deleteOne({ _id: testTurf._id });
        await mongoose.connection.close();
    } catch (err) {
        console.error('Teardown error:', err);
    }
});

describe('Booking Engine', () => {
    const getTomorrowDate = () => {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    };

    describe('GET /api/customer/turfs', () => {
        it('should return list of turfs', async () => {
            const res = await request(app).get('/api/customer/turfs');
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });
    });

    describe('POST /api/customer/bookings', () => {
        it('should create a booking with valid data', async () => {
            const res = await request(app)
                .post('/api/customer/bookings')
                .set('Authorization', `Bearer ${token}`)
                .send({
                    turfId: testTurf._id.toString(),
                    slotId: testSlot._id.toString(),
                    bookingDate: getTomorrowDate(),
                    totalAmount: 500,
                    paymentMethod: 'cash',
                });

            expect(res.statusCode).toBe(201);
            expect(res.body).toHaveProperty('_id');
            expect(res.body.bookingStatus).toBe('confirmed');
        });

        it('should prevent double booking', async () => {
            const res = await request(app)
                .post('/api/customer/bookings')
                .set('Authorization', `Bearer ${token}`)
                .send({
                    turfId: testTurf._id.toString(),
                    slotId: testSlot._id.toString(),
                    bookingDate: getTomorrowDate(),
                    paymentMethod: 'cash',
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toContain('already booked');
        });

        it('should reject booking without auth', async () => {
            const res = await request(app)
                .post('/api/customer/bookings')
                .send({
                    turfId: testTurf._id.toString(),
                    slotId: testSlot._id.toString(),
                    bookingDate: getTomorrowDate(),
                });

            expect(res.statusCode).toBe(401);
        });
    });

    describe('GET /api/customer/bookings', () => {
        it('should return user bookings', async () => {
            const res = await request(app)
                .get('/api/customer/bookings')
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            expect(res.body.length).toBeGreaterThan(0);
        });
    });
});
