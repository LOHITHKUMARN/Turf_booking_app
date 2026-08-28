require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');
const http = require('http');

// Create a test app instance
const createTestApp = () => {
    const app = express();
    app.use(express.json());

    // Routes
    app.use('/api/auth', require('../src/routes/auth.routes'));
    app.use('/api/customer', require('../src/routes/customer.routes'));
    app.use('/api/owner', require('../src/routes/owner.routes'));
    app.use('/api/admin', require('../src/routes/admin.routes'));
    app.use('/api/staff', require('../src/routes/staff.routes'));
    app.use('/api/reviews', require('../src/routes/review.routes'));

    // Error handler
    app.use((err, req, res, next) => {
        const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
        res.status(statusCode).json({ message: err.message });
    });

    return app;
};

let server;
let app;

beforeAll(async () => {
    await mongoose.connect(process.env.MONGODB_URI);
    app = createTestApp();
    server = http.createServer(app);
});

afterAll(async () => {
    await mongoose.connection.close();
    if (server) server.close();
});

module.exports = { createTestApp, getApp: () => app };
