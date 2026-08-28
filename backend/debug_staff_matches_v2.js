const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');
const Tournament = require('./src/models/Tournament');
const TournamentMatch = require('./src/models/TournamentMatch');

dotenv.config();

async function check() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('--- DATABASE DIAGNOSIS ---');

    const staff = await User.findOne({ email: 'varun@gmail.com' });
    console.log('Staff User:', staff.email, 'ID:', staff._id);
    console.log('Assigned Turf ID:', staff.assignedTurfId);

    const tournaments = await Tournament.find({ turfId: staff.assignedTurfId });
    console.log('Tournaments at this Turf:', tournaments.length);
    tournaments.forEach(t => console.log(` - ${t.name} (ID: ${t._id}, Status: ${t.status})`));

    const tournamentIds = tournaments.map(t => t._id);
    const matches = await TournamentMatch.find({ tournamentId: { $in: tournamentIds } });
    console.log('Matches for these Tournaments:', matches.length);
    matches.forEach(m => {
        console.log(` - Match ID: ${m._id}, Tournament: ${m.tournamentId}, Status: ${m.status}, StartTime: ${m.startTime}`);
    });

    console.log('--- ALL MATCHES IN DB ---');
    const allMatches = await TournamentMatch.find({});
    console.log('Total matches in DB:', allMatches.length);
    allMatches.forEach(m => {
        console.log(` - Match: ${m._id}, Status: ${m.status}, Tournament: ${m.tournamentId}`);
    });

    await mongoose.disconnect();
}

check();
