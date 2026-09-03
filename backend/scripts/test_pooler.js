const { PrismaClient } = require('@prisma/client');

const testSessionPooler = async () => {
    // Session mode on port 5432
    const url = 'postgresql://postgres.fulaepdwvwuryhiiznyv:Lohith%400987@aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres';
    console.log('Testing Session Pooler (port 5432)...');
    
    const prisma = new PrismaClient({
        datasources: {
            db: { url }
        }
    });

    try {
        const count = await prisma.user.count();
        console.log('🎉 SUCCESS! Connected via Supabase Session Pooler (Port 5432). User count:', count);
        await prisma.$disconnect();
        return true;
    } catch (err) {
        console.error('❌ Port 5432 failed:', err.message);
        await prisma.$disconnect();
        return false;
    }
};

const testTransactionPooler = async () => {
    // Transaction mode on port 6543
    const url = 'postgresql://postgres.fulaepdwvwuryhiiznyv:Lohith%400987@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres?pgbouncer=true';
    console.log('\nTesting Transaction Pooler (port 6543)...');
    
    const prisma = new PrismaClient({
        datasources: {
            db: { url }
        }
    });

    try {
        const count = await prisma.user.count();
        console.log('🎉 SUCCESS! Connected via Supabase Transaction Pooler (Port 6543). User count:', count);
        await prisma.$disconnect();
        return true;
    } catch (err) {
        console.error('❌ Port 6543 failed:', err.message);
        await prisma.$disconnect();
        return false;
    }
};

const run = async () => {
    const s1 = await testSessionPooler();
    const s2 = await testTransactionPooler();
    if (s1 || s2) {
        console.log('\n✅ At least one pooler mode works perfectly with IPv4!');
        process.exit(0);
    } else {
        process.exit(1);
    }
};

run();
