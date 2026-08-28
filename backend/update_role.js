const mongoose = require('mongoose');
const User = require('./src/models/User');
require('dotenv').config();

const updateRole = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        const userId = '69beb836984ccb17d0becd33';
        const user = await User.findById(userId);
        if (user) {
            user.role = 'admin';
            await user.save();
            console.log(`User ${user.email} updated to admin role.`);
        } else {
            console.log('User not found.');
        }
        process.exit(0);
    } catch (error) {
        console.error('Error updating role:', error);
        process.exit(1);
    }
};

updateRole();
