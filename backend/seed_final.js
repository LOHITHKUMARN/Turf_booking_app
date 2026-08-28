require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

const seed = async () => {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected!');

        const adminExists = await User.findOne({ email: 'admin@turf.com' });
        if (adminExists) {
            console.log('Admin user already exists');
            process.exit(0);
        }

        console.log('Creating admin user...');
        const admin = new User({
            name: 'Super Admin',
            email: 'admin@turf.com',
            phone: '0000000000',
            password: 'AdminPassword123!',
            role: 'admin'
        });

        await admin.save();
        console.log('Admin user created successfully!');
        process.exit(0);
    } catch (err) {
        console.error('Seed failed - Detailed Error:');
        console.error(err);
        if (err.errors) {
            console.error('Validation Errors:', JSON.stringify(err.errors, null, 2));
        }
        process.exit(1);
    }
};

seed();
