require('dotenv').config();
const mongoose = require('mongoose');
const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('./src/models/User');
const Payout = require('./src/models/Payout');

const app = express();
app.use(express.json());
app.use('/api/owner', require('./src/routes/owner.routes'));

async function test() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    const owner = await User.findOne({ role: 'owner' });
    if (!owner) {
        console.log('No owner found');
        process.exit(1);
    }
    console.log('Using owner:', owner.email);

    const token = jwt.sign({ userId: owner._id, role: 'owner' }, process.env.JWT_SECRET);
    console.log('Generated Token:', token);

    const res = await request(app)
        .get('/api/owner/payouts')
        .set('Authorization', `Bearer ${token}`);

    console.log('Response Status:', res.statusCode);
    console.log('Response Body:', JSON.stringify(res.body, null, 2));

    await mongoose.connection.close();
}

test();
