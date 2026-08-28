const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Tournament = require('./src/models/Tournament');

dotenv.config();

async function check() {
    await mongoose.connect(process.env.MONGODB_URI);
    const all = await Tournament.find({});
    console.log('--- ALL TOURNAMENTS ---');
    all.forEach(t => {
        console.log(`NAME: "${t.name}" | STATUS: "${t.status}" | SPORT: "${t.sportsType}"`);
    });
    await mongoose.disconnect();
}

check();
