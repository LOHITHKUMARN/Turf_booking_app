const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const testStaffCreation = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB connected');

        const staffData = {
            name: 'New Staff',
            email: 'newstaff_' + Date.now() + '@example.com',
            phone: '555' + Date.now().toString().slice(-7),
            password: 'password123',
            role: 'staff',
            ownerId: new mongoose.Types.ObjectId()
        };

        console.log('Simulating staff creation with password:', staffData.password);

        // This simulates ownerController.createStaff using User.create
        const staff = await User.create(staffData);

        console.log('Staff created. ID:', staff._id);
        console.log('Stored password hash:', staff.password);

        const isMatch = await staff.matchPassword('password123');
        console.log(`Checking match for "password123": ${isMatch ? 'MATCHED' : 'FAILED'}`);

        // Try to log in as if we are the authController
        const foundStaff = await User.findOne({ email: staffData.email });
        if (foundStaff && await foundStaff.matchPassword('password123')) {
            console.log('Login simulation: SUCCESS');
        } else {
            console.log('Login simulation: FAILED');
        }

        // Clean up
        await User.deleteOne({ _id: staff._id });
        console.log('Test staff deleted');

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

testStaffCreation();
