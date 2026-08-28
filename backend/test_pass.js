const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const testPassword = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB connected');

        const email = 'viju@gmail.com';
        const user = await User.findOne({ email });

        if (!user) {
            console.log('User not found');
            process.exit(1);
        }

        console.log('User found:', user.email);
        user.password = '123456';
        await user.save();
        console.log('Password reset to "123456" for viju@gmail.com');
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

testPassword();
