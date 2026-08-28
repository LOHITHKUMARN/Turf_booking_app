const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');
const Tournament = require('./src/models/Tournament');
const TournamentMatch = require('./src/models/TournamentMatch');

dotenv.config();

async function check() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    const staff = await User.findOne({ email: 'varun@gmail.com' });
    console.log('Staff:', staff.name, 'Assigned Turf:', staff.assignedTurfId);

    const tournaments = await Tournament.find({ turfId: staff.assignedTurfId });
    console.log('Tournaments for this turf:', tournaments.map(t => ({ id: t._id, name: t.name })));

    const tournamentIds = tournaments.map(t => t._id);
    const matches = await TournamentMatch.find({ tournamentId: { $in: tournamentIds } });
    console.log('Matches for these tournaments:', matches.length, 'Statuses:', [...new Set(matches.map(m => m.status))]);

    await mongoose.disconnect();
}

check();
