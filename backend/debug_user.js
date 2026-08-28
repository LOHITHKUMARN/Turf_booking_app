const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./src/models/User');

async function checkUser() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const userByEmail = await User.findOne({ email: 'chandans@gmail.com' });
        const userByPhone = await User.findOne({ phone: '75544123698' });

        if (userByEmail) {
            console.log('User found by email:');
            console.log(userByEmail);
        }
        if (userByPhone) {
            console.log('User found by phone:');
            console.log(userByPhone);
        }
        if (!userByEmail && !userByPhone) {
            console.log('User NOT found by both email and phone');
        }
    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.disconnect();
    }
}

checkUser();
