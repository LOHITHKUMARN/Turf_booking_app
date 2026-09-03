require('dotenv').config();
const bcrypt = require('bcryptjs');
const { prisma } = require('../src/config/db');

const seedSupabase = async () => {
    try {
        console.log('Connecting to Supabase PostgreSQL via Prisma...');
        await prisma.$connect();
        console.log('Connected!');

        // 1. Super Admin
        const adminEmail = 'admin@turf.com';
        let admin = await prisma.user.findUnique({ where: { email: adminEmail } });
        if (!admin) {
            console.log('Creating Super Admin...');
            admin = await prisma.user.create({
                data: {
                    name: 'Super Admin',
                    email: adminEmail,
                    phone: '0000000000',
                    password: await bcrypt.hash('AdminPassword123!', 10),
                    role: 'admin',
                    status: 'active'
                }
            });
        }
        console.log(`✅ Admin: ${admin.email}`);

        // 2. Turf Owner
        const ownerEmail = 'owner@turf.com';
        let owner = await prisma.user.findUnique({ where: { email: ownerEmail } });
        if (!owner) {
            console.log('Creating Turf Owner...');
            owner = await prisma.user.create({
                data: {
                    name: 'Viju Arena Owner',
                    email: ownerEmail,
                    phone: '9876543210',
                    password: await bcrypt.hash('OwnerPassword123!', 10),
                    role: 'owner',
                    status: 'active'
                }
            });
        }
        console.log(`✅ Owner: ${owner.email}`);

        // 3. Turf Venue
        let turf = await prisma.turf.findFirst({ where: { ownerId: owner.id } });
        if (!turf) {
            console.log('Creating Sample Turf Venue...');
            turf = await prisma.turf.create({
                data: {
                    ownerId: owner.id,
                    name: 'GreenField Sports Arena',
                    turfType: 'both',
                    city: 'Bangalore',
                    area: 'Koramangala',
                    grounds: ['Ground A (Football)', 'Ground B (Cricket)'],
                    sports: ['Football', 'Cricket'],
                    amenities: ['Floodlights', 'Changing Room', 'Parking', 'Drinking Water', 'First Aid'],
                    images: [
                        'https://images.unsplash.com/photo-1529900240041-22f1ae52850e?auto=format&fit=crop&w=800&q=80',
                        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80'
                    ],
                    status: 'approved',
                    operationalStatus: 'normal',
                    minBookingDuration: 1,
                    advanceBookingLimit: 7,
                    bookingCutoffTime: 2,
                    gracePeriod: 15,
                    maxMembers: 14,
                    upiId: 'owner@upi',
                    taxPercentage: 5.0,
                    avgRating: 4.8,
                    numReviews: 12
                }
            });
        }
        console.log(`✅ Turf: ${turf.name} (${turf.id})`);

        // 4. Ground Staff
        const staffEmail = 'staff@turf.com';
        let staff = await prisma.user.findUnique({ where: { email: staffEmail } });
        if (!staff) {
            console.log('Creating Turf Staff...');
            staff = await prisma.user.create({
                data: {
                    name: 'Ground Manager Ravi',
                    email: staffEmail,
                    phone: '9876543211',
                    password: await bcrypt.hash('StaffPassword123!', 10),
                    role: 'staff',
                    status: 'active',
                    ownerId: owner.id,
                    assignedTurfId: turf.id,
                    assignedGround: 'Ground A (Football)'
                }
            });
        }
        console.log(`✅ Staff: ${staff.email}`);

        // 5. Customer
        const customerEmail = 'customer@turf.com';
        let customer = await prisma.user.findUnique({ where: { email: customerEmail } });
        if (!customer) {
            console.log('Creating Customer...');
            customer = await prisma.user.create({
                data: {
                    name: 'Rahul Athlete',
                    email: customerEmail,
                    phone: '9876543212',
                    password: await bcrypt.hash('CustomerPassword123!', 10),
                    role: 'customer',
                    status: 'active'
                }
            });
        }
        console.log(`✅ Customer: ${customer.email}`);

        // 6. Slots Generation (for every day of the week)
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const times = [
            { start: '06:00', end: '07:00', price: 800 },
            { start: '07:00', end: '08:00', price: 800 },
            { start: '08:00', end: '09:00', price: 1000 },
            { start: '17:00', end: '18:00', price: 1200 },
            { start: '18:00', end: '19:00', price: 1400 },
            { start: '19:00', end: '20:00', price: 1400 },
            { start: '20:00', end: '21:00', price: 1200 }
        ];

        console.log('Generating recurring slots across 7 days...');
        let slotsCount = 0;
        for (const day of days) {
            for (const time of times) {
                await prisma.slot.upsert({
                    where: {
                        turfId_groundName_sport_dayOfWeek_startTime: {
                            turfId: turf.id,
                            groundName: 'Ground A (Football)',
                            sport: 'Football',
                            dayOfWeek: day,
                            startTime: time.start
                        }
                    },
                    update: {
                        endTime: time.end,
                        price: time.price
                    },
                    create: {
                        turfId: turf.id,
                        groundName: 'Ground A (Football)',
                        sport: 'Football',
                        dayOfWeek: day,
                        startTime: time.start,
                        endTime: time.end,
                        price: time.price
                    }
                });
                slotsCount++;
            }
        }
        console.log(`✅ Slots generated: ${slotsCount} active slots.`);

        console.log('\n====================================================');
        console.log('🎉 SEEDING COMPLETE FOR ALL 4 ROLES:');
        console.log('====================================================');
        console.log('1. Admin:    admin@turf.com    / AdminPassword123!');
        console.log('2. Owner:    owner@turf.com    / OwnerPassword123!');
        console.log('3. Staff:    staff@turf.com    / StaffPassword123!');
        console.log('4. Customer: customer@turf.com / CustomerPassword123!');
        console.log('====================================================\n');

        await prisma.$disconnect();
        process.exit(0);
    } catch (err) {
        console.error('Seeding failed:', err);
        await prisma.$disconnect();
        process.exit(1);
    }
};

seedSupabase();
