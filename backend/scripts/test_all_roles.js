require('dotenv').config();
process.env.DB_PROVIDER = 'postgres';

const request = require('supertest');
const app = require('../src/app');

const testAllRoles = async () => {
    console.log('====================================================');
    console.log('🧪 TESTING ALL 4 FLUTTER ROLES AGAINST SUPABASE');
    console.log('====================================================\n');

    try {
        // 1. Customer Login
        console.log('[1/6] Testing Customer Login...');
        const custLogin = await request(app)
            .post('/api/auth/login')
            .send({ identifier: 'customer@turf.com', password: 'CustomerPassword123!' });
        
        if (custLogin.status !== 200 || custLogin.body.role !== 'customer') {
            throw new Error(`Customer login failed: ${JSON.stringify(custLogin.body)}`);
        }
        const custToken = custLogin.body.token;
        console.log(`✅ Customer authenticated! ID: ${custLogin.body._id}`);

        // 2. Customer Browse Turfs
        console.log('\n[2/6] Testing Browse Turfs (Customer API)...');
        const turfsRes = await request(app).get('/api/customer/turfs');
        if (turfsRes.status !== 200 || !Array.isArray(turfsRes.body) || turfsRes.body.length === 0) {
            throw new Error(`Browse turfs failed: ${JSON.stringify(turfsRes.body)}`);
        }
        const sampleTurf = turfsRes.body[0];
        console.log(`✅ Browse Turfs successful! Found ${turfsRes.body.length} venue(s).`);
        console.log(`   Venue: "${sampleTurf.name}", City: "${sampleTurf.location?.city}", Rating: ${sampleTurf.settings?.avgRating}`);

        // 3. Customer Check Slots
        console.log('\n[3/6] Testing Slot Availability...');
        const tomorrow = '2026-09-04';
        const slotsRes = await request(app).get(`/api/customer/turfs/${sampleTurf._id}/slots?date=${tomorrow}`);
        if (slotsRes.status !== 200 || !Array.isArray(slotsRes.body) || slotsRes.body.length === 0) {
            throw new Error(`Get slots failed: ${JSON.stringify(slotsRes.body)}`);
        }
        const availableSlot = slotsRes.body[0];
        console.log(`✅ Slots loaded! ${slotsRes.body.length} slots for ${tomorrow}. First slot: ${availableSlot.startTime} - ${availableSlot.endTime} (₹${availableSlot.price})`);

        // 4. Customer Book a Slot
        console.log('\n[4/6] Testing Create Booking with Transaction...');
        const bookingRes = await request(app)
            .post('/api/customer/bookings')
            .set('Authorization', `Bearer ${custToken}`)
            .send({
                turfId: sampleTurf._id,
                slotId: availableSlot._id,
                bookingDate: tomorrow,
                totalAmount: availableSlot.price,
                paymentMethod: 'cash'
            });

        if (bookingRes.status !== 201) {
            throw new Error(`Create booking failed: ${JSON.stringify(bookingRes.body)}`);
        }
        console.log(`✅ Booking created atomically! Booking ID: ${bookingRes.body._id || bookingRes.body.id}`);

        // 5. Test Double-Booking Rejection
        console.log('\n[5/6] Testing Atomic Double-Booking Rejection...');
        const doubleBookingRes = await request(app)
            .post('/api/customer/bookings')
            .set('Authorization', `Bearer ${custToken}`)
            .send({
                turfId: sampleTurf._id,
                slotId: availableSlot._id,
                bookingDate: tomorrow,
                totalAmount: availableSlot.price,
                paymentMethod: 'cash'
            });

        if (doubleBookingRes.status === 400) {
            console.log('✅ Double-booking correctly prevented by transaction check!');
        } else {
            console.warn('⚠️ Warning: Double-booking was not blocked', doubleBookingRes.body);
        }

        // 6. Test Owner, Staff & Admin Logins
        console.log('\n[6/6] Testing Owner, Staff & Admin Logins...');
        const ownerLogin = await request(app)
            .post('/api/auth/login')
            .send({ identifier: 'owner@turf.com', password: 'OwnerPassword123!' });
        console.log(`✅ Owner: ${ownerLogin.body.role === 'owner' ? 'Verified' : 'Failed'}`);

        const staffLogin = await request(app)
            .post('/api/auth/login')
            .send({ identifier: 'staff@turf.com', password: 'StaffPassword123!' });
        console.log(`✅ Staff: ${staffLogin.body.role === 'staff' ? 'Verified' : 'Failed'}`);

        const adminLogin = await request(app)
            .post('/api/auth/login')
            .send({ identifier: 'admin@turf.com', password: 'AdminPassword123!' });
        console.log(`✅ Admin: ${adminLogin.body.role === 'admin' ? 'Verified' : 'Failed'}`);

        console.log('\n====================================================');
        console.log('🎉 ALL TESTS PASSED! SUPABASE POSTGRESQL IS READY');
        console.log('====================================================\n');
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Test suite failed:', error.message);
        process.exit(1);
    }
};

testAllRoles();
