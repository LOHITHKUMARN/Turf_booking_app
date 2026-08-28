const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const testCreate = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB connected');

        const email = 'test_create_' + Date.now() + '@example.com';
        const password = 'testpassword';

        console.log('Creating user with password:', password);
        const user = await User.create({
            name: 'Test Create',
            email,
            phone: '123' + Date.now().toString().slice(-7),
            password,
            role: 'staff'
        });

        console.log('User created. Role:', user.role);
        console.log('Stored password hash:', user.password);

        const isMatch = await user.matchPassword(password);
        console.log(`Checking match for "${password}": ${isMatch ? 'MATCHED' : 'FAILED'}`);

        // Clean up
        await User.deleteOne({ _id: user._id });
        console.log('Test user deleted');

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

testCreate();
