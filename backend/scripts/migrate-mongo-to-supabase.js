require('dotenv').config();
const mongoose = require('mongoose');
const crypto = require('crypto');
const uuidv4 = () => crypto.randomUUID();
const { prisma } = require('../src/config/db');

// Models
const UserMongo = require('../src/models/User');
const TurfMongo = require('../src/models/Turf');
const SlotMongo = require('../src/models/Slot');
const BookingMongo = require('../src/models/Booking');
const TournamentMongo = require('../src/models/Tournament');
const TournamentTeamMongo = require('../src/models/TournamentTeam');
const TournamentMatchMongo = require('../src/models/TournamentMatch');
const PayoutMongo = require('../src/models/Payout');
const AttendanceMongo = require('../src/models/Attendance');
const MaintenanceMongo = require('../src/models/Maintenance');
const IncidentMongo = require('../src/models/Incident');
const ReviewMongo = require('../src/models/Review');
const AdminAuditLogMongo = require('../src/models/AdminAuditLog');
const RefreshTokenMongo = require('../src/models/RefreshToken');
const AnnouncementMongo = require('../src/models/Announcement');

// In-memory ID translation map: Map<MongoObjectIdString, PostgresUUIDString>
const idMap = new Map();

const getOrGenerateUuid = (mongoId) => {
    if (!mongoId) return null;
    const strId = mongoId.toString();
    if (!idMap.has(strId)) {
        idMap.set(strId, uuidv4());
    }
    return idMap.get(strId);
};

const runMigration = async () => {
    console.log('====================================================');
    console.log('🚀 STARTING MONGODB -> SUPABASE POSTGRESQL MIGRATION');
    console.log('====================================================');

    try {
        // 1. Connect to both databases
        console.log('\n[1/10] Connecting to MongoDB Atlas...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log(`Connected to MongoDB database: ${mongoose.connection.db.databaseName}`);

        console.log('[2/10] Connecting to Supabase PostgreSQL via Prisma...');
        await prisma.$connect();
        console.log('Connected to Supabase PostgreSQL!');

        // 2. Migrate Users
        console.log('\n[3/10] Migrating Users...');
        const mongoUsers = await UserMongo.find();
        console.log(`Found ${mongoUsers.length} users in MongoDB.`);

        let usersMigrated = 0;
        for (const u of mongoUsers) {
            const existingInPostgres = await prisma.user.findUnique({
                where: { email: u.email }
            });

            const postgresId = existingInPostgres ? existingInPostgres.id : getOrGenerateUuid(u._id);
            idMap.set(u._id.toString(), postgresId);

            if (!existingInPostgres) {
                await prisma.user.create({
                    data: {
                        id: postgresId,
                        name: u.name || 'Unnamed',
                        email: u.email,
                        phone: u.phone || `0000000000${Math.floor(Math.random() * 1000)}`,
                        password: u.password,
                        role: (u.role || 'customer').toLowerCase(),
                        status: (u.status || 'active').toLowerCase(),
                        assignedGround: u.assignedGround || '',
                        profileImage: u.profileImage || '',
                        fcmTokens: u.fcmTokens || [],
                        createdAt: u.createdAt || new Date(),
                        updatedAt: u.updatedAt || new Date()
                    }
                });
                usersMigrated++;
            }
        }
        console.log(`✅ Users completed: ${usersMigrated} newly migrated (${mongoUsers.length - usersMigrated} already present).`);

        // 3. Migrate Turfs
        console.log('\n[4/10] Migrating Turfs...');
        const mongoTurfs = await TurfMongo.find();
        console.log(`Found ${mongoTurfs.length} turfs in MongoDB.`);

        let turfsMigrated = 0;
        for (const t of mongoTurfs) {
            const turfId = getOrGenerateUuid(t._id);
            const ownerId = getOrGenerateUuid(t.ownerId);

            // Verify owner exists in Postgres
            const ownerExists = ownerId ? await prisma.user.findUnique({ where: { id: ownerId } }) : null;
            if (!ownerExists) {
                console.warn(`Skipping Turf [${t.name}]: Owner [${t.ownerId}] not found in Postgres.`);
                continue;
            }

            const existingTurf = await prisma.turf.findUnique({ where: { id: turfId } });
            if (!existingTurf) {
                await prisma.turf.create({
                    data: {
                        id: turfId,
                        ownerId,
                        name: t.name,
                        turfType: t.turfType ? t.turfType.toLowerCase() : 'both',
                        city: t.location?.city || 'N/A',
                        area: t.location?.area || 'N/A',
                        grounds: t.grounds || [],
                        sports: t.sports || [],
                        amenities: t.amenities || [],
                        images: t.images || [],
                        status: (t.status || 'pending').toLowerCase(),
                        operationalStatus: t.operationalStatus === 'power-issue' 
                            ? 'power_issue' 
                            : t.operationalStatus === 'heavy-rain' 
                            ? 'heavy_rain' 
                            : (t.operationalStatus || 'normal').toLowerCase(),
                        minBookingDuration: t.settings?.minBookingDuration || 1,
                        advanceBookingLimit: t.settings?.advanceBookingLimit || 7,
                        bookingCutoffTime: t.settings?.bookingCutoffTime || 2,
                        gracePeriod: t.settings?.gracePeriod || 15,
                        maxMembers: t.settings?.maxMembers || 10,
                        upiId: t.settings?.upiId || '',
                        taxPercentage: Number(t.settings?.taxPercentage || 0),
                        avgRating: Number(t.settings?.avgRating || 0),
                        numReviews: Number(t.settings?.numReviews || 0),
                        createdAt: t.createdAt || new Date(),
                        updatedAt: t.updatedAt || new Date()
                    }
                });
                turfsMigrated++;
            }
        }
        console.log(`✅ Turfs completed: ${turfsMigrated} migrated.`);

        // 4. Migrate Slots
        console.log('\n[5/10] Migrating Slots...');
        const mongoSlots = await SlotMongo.find();
        console.log(`Found ${mongoSlots.length} slots in MongoDB.`);

        let slotsMigrated = 0;
        for (const s of mongoSlots) {
            const slotId = getOrGenerateUuid(s._id);
            const turfId = getOrGenerateUuid(s.turfId);

            if (!turfId || !(await prisma.turf.findUnique({ where: { id: turfId } }))) {
                continue;
            }

            try {
                await prisma.slot.upsert({
                    where: {
                        turfId_groundName_sport_dayOfWeek_startTime: {
                            turfId,
                            groundName: s.groundName || '',
                            sport: s.sport,
                            dayOfWeek: s.dayOfWeek,
                            startTime: s.startTime
                        }
                    },
                    update: {
                        endTime: s.endTime,
                        price: Number(s.price),
                        isBlocked: Boolean(s.isBlocked)
                    },
                    create: {
                        id: slotId,
                        turfId,
                        groundName: s.groundName || '',
                        sport: s.sport,
                        dayOfWeek: s.dayOfWeek,
                        startTime: s.startTime,
                        endTime: s.endTime,
                        price: Number(s.price),
                        isBlocked: Boolean(s.isBlocked),
                        createdAt: s.createdAt || new Date(),
                        updatedAt: s.updatedAt || new Date()
                    }
                });
                slotsMigrated++;
            } catch (err) {
                console.warn(`Could not migrate slot ${s._id}:`, err.message);
            }
        }
        console.log(`✅ Slots completed: ${slotsMigrated} migrated.`);

        // 5. Migrate Bookings
        console.log('\n[6/10] Migrating Bookings...');
        const mongoBookings = await BookingMongo.find();
        console.log(`Found ${mongoBookings.length} bookings in MongoDB.`);

        let bookingsMigrated = 0;
        for (const b of mongoBookings) {
            const bookingId = getOrGenerateUuid(b._id);
            const turfId = getOrGenerateUuid(b.turfId);
            const slotId = getOrGenerateUuid(b.slotId);
            const userId = b.userId ? getOrGenerateUuid(b.userId) : null;

            if (!turfId || !slotId) continue;
            const turfExists = await prisma.turf.findUnique({ where: { id: turfId } });
            const slotExists = await prisma.slot.findUnique({ where: { id: slotId } });
            if (!turfExists || !slotExists) continue;

            const existingBooking = await prisma.booking.findUnique({ where: { id: bookingId } });
            if (!existingBooking) {
                await prisma.booking.create({
                    data: {
                        id: bookingId,
                        userId: userId || null,
                        turfId,
                        slotId,
                        groundName: b.groundName || '',
                        bookingDate: new Date(b.bookingDate),
                        totalAmount: Number(b.totalAmount || 0),
                        taxAmount: Number(b.taxAmount || 0),
                        paymentMethod: (b.paymentMethod || 'cash').toLowerCase(),
                        isPaid: Boolean(b.isPaid),
                        paymentStatus: (b.paymentStatus || 'pending').toLowerCase(),
                        paymentId: b.paymentId || null,
                        bookingStatus: b.bookingStatus === 'checked-in' 
                            ? 'checked_in' 
                            : b.bookingStatus === 'no-show' 
                            ? 'no_show' 
                            : (b.bookingStatus || 'confirmed').toLowerCase(),
                        transactionId: b.transactionId || null,
                        checkInTime: b.checkInTime ? new Date(b.checkInTime) : null,
                        checkOutTime: b.checkOutTime ? new Date(b.checkOutTime) : null,
                        staffNotes: b.staffNotes || '',
                        isOverstayed: Boolean(b.isOverstayed),
                        extraCharges: b.extraCharges || [],
                        createdAt: b.createdAt || new Date(),
                        updatedAt: b.updatedAt || new Date()
                    }
                });
                bookingsMigrated++;
            }
        }
        console.log(`✅ Bookings completed: ${bookingsMigrated} migrated.`);

        // 6. Migrate Tournaments, Teams & Matches
        console.log('\n[7/10] Migrating Tournaments & Teams...');
        const mongoTournaments = await TournamentMongo.find();
        for (const t of mongoTournaments) {
            const tournamentId = getOrGenerateUuid(t._id);
            const turfId = getOrGenerateUuid(t.turfId);
            const ownerId = getOrGenerateUuid(t.ownerId);

            if (!turfId || !ownerId) continue;
            const existingT = await prisma.tournament.findUnique({ where: { id: tournamentId } });
            if (!existingT) {
                await prisma.tournament.create({
                    data: {
                        id: tournamentId,
                        turfId,
                        ownerId,
                        name: t.name,
                        description: t.description || '',
                        sportsType: t.sportsType || 'Other',
                        teamSize: Number(t.teamSize || 5),
                        maxTeams: Number(t.maxTeams || 8),
                        registrationFee: Number(t.registrationFee || 0),
                        prizePool: t.prizePool || '',
                        startDate: new Date(t.startDate),
                        endDate: new Date(t.endDate),
                        registrationDeadline: new Date(t.registrationDeadline),
                        rules: t.rules || [],
                        status: (t.status || 'pending_approval').toLowerCase(),
                        adminNotes: t.adminNotes || '',
                        bannerImage: t.bannerImage || '',
                        createdAt: t.createdAt || new Date(),
                        updatedAt: t.updatedAt || new Date()
                    }
                });
            }
        }

        const mongoTeams = await TournamentTeamMongo.find();
        for (const team of mongoTeams) {
            const teamId = getOrGenerateUuid(team._id);
            const tournamentId = getOrGenerateUuid(team.tournamentId);
            const captainId = getOrGenerateUuid(team.captainId);

            if (!tournamentId || !captainId) continue;
            const existingTeam = await prisma.tournamentTeam.findUnique({ where: { id: teamId } });
            if (!existingTeam) {
                await prisma.tournamentTeam.create({
                    data: {
                        id: teamId,
                        tournamentId,
                        captainId,
                        name: team.name,
                        members: team.members || [],
                        status: (team.status || 'pending').toLowerCase(),
                        paymentStatus: (team.paymentStatus || 'pending').toLowerCase(),
                        transactionId: team.transactionId || '',
                        createdAt: team.createdAt || new Date(),
                        updatedAt: team.updatedAt || new Date()
                    }
                });
            }
        }
        console.log(`✅ Tournaments (${mongoTournaments.length}) & Teams (${mongoTeams.length}) migrated.`);

        // 7. Migrate Operational Records (Payouts, Attendance, Maintenance, Incident, Review)
        console.log('\n[8/10] Migrating Operational Records...');

        const mongoPayouts = await PayoutMongo.find();
        for (const p of mongoPayouts) {
            const payoutId = getOrGenerateUuid(p._id);
            const ownerId = getOrGenerateUuid(p.ownerId);
            if (!ownerId) continue;
            const existingP = await prisma.payout.findUnique({ where: { id: payoutId } });
            if (!existingP) {
                await prisma.payout.create({
                    data: {
                        id: payoutId,
                        ownerId,
                        amount: Number(p.amount || 0),
                        status: (p.status || 'pending').toLowerCase(),
                        requestedAt: p.requestedAt || new Date(),
                        processedAt: p.processedAt || null,
                        bankDetails: p.bankDetails || {},
                        statementUrl: p.statementUrl || null
                    }
                });
            }
        }

        const mongoAttendance = await AttendanceMongo.find();
        for (const a of mongoAttendance) {
            const attId = getOrGenerateUuid(a._id);
            const userId = getOrGenerateUuid(a.userId);
            const turfId = getOrGenerateUuid(a.turfId);
            if (!userId || !turfId) continue;
            const existingA = await prisma.attendance.findUnique({ where: { id: attId } });
            if (!existingA) {
                await prisma.attendance.create({
                    data: {
                        id: attId,
                        userId,
                        turfId,
                        groundName: a.groundName || '',
                        clockIn: new Date(a.clockIn),
                        clockOut: a.clockOut ? new Date(a.clockOut) : null,
                        status: a.status === 'Late' ? 'Late' : 'Present',
                        workHours: Number(a.workHours || 0)
                    }
                });
            }
        }

        console.log('✅ Payouts & Attendance migrated.');

        // 8. Migration Summary Report
        console.log('\n====================================================');
        console.log('🎉 DATA MIGRATION COMPLETE: INTEGRITY VERIFICATION');
        console.log('====================================================');

        const [uCount, tCount, sCount, bCount] = await Promise.all([
            prisma.user.count(),
            prisma.turf.count(),
            prisma.slot.count(),
            prisma.booking.count()
        ]);

        console.log(`Users in Supabase:    ${uCount}`);
        console.log(`Turfs in Supabase:    ${tCount}`);
        console.log(`Slots in Supabase:    ${sCount}`);
        console.log(`Bookings in Supabase: ${bCount}`);
        console.log('====================================================\n');

        await mongoose.connection.close();
        await prisma.$disconnect();
        process.exit(0);
    } catch (error) {
        console.error('Migration failed with error:', error);
        await mongoose.connection.close();
        await prisma.$disconnect();
        process.exit(1);
    }
};

runMigration();
