require('dotenv').config();
const mongoose = require('mongoose');

const testConn = async () => {
    try {
        console.log('Attempting to connect to:', process.env.MONGODB_URI.split('@')[1]); // Log only the host part for safety
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected successfully!');
        const collections = await mongoose.connection.db.listCollections().toArray();
        console.log('Collections:', collections.map(c => c.name));

        const owner = await mongoose.connection.db.collection('users').findOne({ role: 'owner' });
        if (owner) {
            console.log('OWNER_EMAIL:', owner.email);
        } else {
            console.log('NO_OWNER_FOUND');
        }
        process.exit(0);
    } catch (err) {
        console.error('Connection failed:', err);
        process.exit(1);
    }
};

testConn();
