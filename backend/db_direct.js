require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const dbTest = async () => {
    try {
        console.log('Connecting...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected!');

        const db = mongoose.connection.db;
        const users = db.collection('users');

        const hashedPassword = await bcrypt.hash('AdminPassword123!', 10);

        console.log('Inserting user directly...');
        const result = await users.insertOne({
            name: 'Super Admin',
            email: 'admin@turf.com',
            phone: '0000000000',
            password: hashedPassword,
            role: 'admin',
            status: 'active',
            createdAt: new Date(),
            updatedAt: new Date()
        });

        console.log('User inserted directly:', result.insertedId);
        process.exit(0);
    } catch (err) {
        console.error('Direct insert failed:');
        console.error(err);
        process.exit(1);
    }
};

dbTest();
