require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

const seedAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB for seeding...');

        const adminExists = await User.findOne({ email: 'admin@turf.com' });

        if (adminExists) {
            console.log('Admin already exists');
            process.exit();
        }

        console.log('Seeding admin user...');
        const admin = await User.create({
            name: 'Super Admin',
            email: 'admin@turf.com',
            phone: '0000000000',
            password: 'AdminPassword123!',
            role: 'admin'
        });

        console.log('Admin user created successfully:', admin._id);
        process.exit();
    } catch (error) {
        console.error('Detailed error seeding admin:', error);
        if (error.code === 11000) {
            console.error('Duplicate key error - check email or phone');
        }
        process.exit(1);
    }
};

seedAdmin();
