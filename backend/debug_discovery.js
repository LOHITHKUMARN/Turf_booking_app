const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Tournament = require('./src/models/Tournament');
const Turf = require('./src/models/Turf');

dotenv.config();

async function check() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('--- PUBLIC DISCOVERY CHECK ---');

    const tournaments = await Tournament.find({ status: { $in: ['open', 'ongoing'] } }).populate('turfId');
    console.log('Total Public Tournaments Found:', tournaments.length);

    tournaments.forEach(t => {
        console.log(` - ${t.name}: Status=${t.status}, Sport=${t.sportsType}, City=${t.turfId?.location?.city}, TurfName=${t.turfId?.name}`);
    });

    console.log('--- ALL TOURNAMENTS (ANY STATUS) ---');
    const all = await Tournament.find({});
    all.forEach(t => {
        console.log(` - ${t.name}: Status=${t.status}`);
    });

    await mongoose.disconnect();
}

check();
