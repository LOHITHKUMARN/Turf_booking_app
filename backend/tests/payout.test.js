require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../src/models/User');
const Turf = require('../src/models/Turf');
const Booking = require('../src/models/Booking');
const Payout = require('../src/models/Payout');
const Slot = require('../src/models/Slot');

const app = require('../src/app');

jest.setTimeout(30000);

let owner, admin, turf, slot;
let ownerToken, adminToken;

beforeAll(async () => {
    try {
        if (mongoose.connection.readyState === 0) {
            await mongoose.connect(process.env.MONGODB_URI);
        }

        // Cleanup
        await User.deleteMany({ email: /test-payout/ });
        
        // Create Users
        owner = await User.create({
            name: 'Test Owner',
            email: 'owner-test-payout@test.com',
            phone: '9000000001',
            password: 'password123',
            role: 'owner'
        });
        ownerToken = jwt.sign({ userId: owner._id, role: 'owner' }, process.env.JWT_SECRET);

        admin = await User.create({
            name: 'Test Admin',
            email: 'admin-test-payout@test.com',
            phone: '9000000002',
            password: 'password123',
            role: 'admin'
        });
        adminToken = jwt.sign({ userId: admin._id, role: 'admin' }, process.env.JWT_SECRET);

        // Create Turf
        turf = await Turf.create({
            ownerId: owner._id,
            name: 'Test Payout Turf',
            location: { city: 'Test City', area: 'Test Area' },
            sports: ['Football'],
            status: 'approved'
        });

        // Create Slot
        slot = await Slot.create({
            turfId: turf._id,
            sport: 'Football',
            dayOfWeek: 'Monday',
            startTime: '10:00',
            endTime: '11:00',
            price: 1000
        });

        // Create 2 Completed Bookings (2000 total revenue)
        await Booking.create([
            {
                turfId: turf._id,
                slotId: slot._id,
                userId: admin._id,
                bookingDate: new Date(),
                totalAmount: 1000,
                bookingStatus: 'completed',
                paymentStatus: 'paid'
            },
            {
                turfId: turf._id,
                slotId: slot._id,
                userId: admin._id,
                bookingDate: new Date(),
                totalAmount: 1000,
                bookingStatus: 'completed',
                paymentStatus: 'paid'
            }
        ]);
    } catch (err) {
        console.error('Setup error in beforeAll:', err);
        throw err;
    }
});

afterAll(async () => {
    await User.deleteMany({ email: /test-payout/ });
    await Turf.deleteOne({ _id: turf._id });
    await Slot.deleteOne({ _id: slot._id });
    await Booking.deleteMany({ turfId: turf._id });
    await Payout.deleteMany({ ownerId: owner._id });
    await mongoose.connection.close();
});

describe('Payout API', () => {
    describe('POST /api/owner/payout/request', () => {
        it('should allow owner to request a valid payout', async () => {
            const res = await request(app)
                .post('/api/owner/payout/request')
                .set('Authorization', `Bearer ${ownerToken}`)
                .send({
                    amount: 500,
                    bankDetails: {
                        accountNumber: '123456789',
                        ifscCode: 'TEST0001',
                        accountHolderName: 'Test Owner'
                    }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.amount).toBe(500);
            expect(res.body.status).toBe('pending');
        });

        it('should reject payout request exceeding balance', async () => {
            // Balance is 2000 - 500 (pending) = 1500
            const res = await request(app)
                .post('/api/owner/payout/request')
                .set('Authorization', `Bearer ${ownerToken}`)
                .send({ amount: 2000 });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('Insufficient balance for payout');
        });

        it('should reject invalid amounts', async () => {
            const res = await request(app)
                .post('/api/owner/payout/request')
                .set('Authorization', `Bearer ${ownerToken}`)
                .send({ amount: -100 });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('Invalid payout amount');
        });

        it('should enforce minimum payout threshold', async () => {
            const res = await request(app)
                .post('/api/owner/payout/request')
                .set('Authorization', `Bearer ${ownerToken}`)
                .send({ amount: 100 });

            expect(res.statusCode).toBe(400);
            expect(res.body.message).toBe('Minimum payout amount is 500');
        });
    });

    describe('Admin Payout Management', () => {
        let payoutId;

        beforeAll(async () => {
            const payout = await Payout.findOne({ ownerId: owner._id });
            payoutId = payout._id;
        });

        it('should allow admin to get all payouts', async () => {
            const res = await request(app)
                .get('/api/admin/payouts')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            expect(res.body.length).toBeGreaterThan(0);
        });

        it('should allow admin to process a payout', async () => {
            const res = await request(app)
                .post(`/api/admin/payout/${payoutId}/status`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({ status: 'processed' });

            expect(res.statusCode).toBe(200);
            expect(res.body.status).toBe('processed');
            expect(res.body).toHaveProperty('processedAt');
        });
    });

    describe('GET /api/owner/payouts', () => {
        it('should allow owner to see their payout history', async () => {
            const res = await request(app)
                .get('/api/owner/payouts')
                .set('Authorization', `Bearer ${ownerToken}`);

            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            expect(res.body[0].ownerId.toString()).toBe(owner._id.toString());
        });
    });
});
