const bcrypt = require('bcryptjs');
const { prisma } = require('../config/db');
const UserMongo = require('../models/User');
const RefreshTokenMongo = require('../models/RefreshToken');
const { serializeUser } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findByEmailOrPhone = async (identifier) => {
    const id = (identifier || '').trim();
    if (isPostgres()) {
        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: { equals: id, mode: 'insensitive' } },
                    { phone: id }
                ]
            }
        });
        return user;
    }
    return await UserMongo.findOne({
        $or: [{ email: id.toLowerCase() }, { phone: id }]
    });
};

const findById = async (id) => {
    if (!id) return null;
    if (isPostgres()) {
        const user = await prisma.user.findUnique({
            where: { id: String(id) }
        });
        return user;
    }
    return await UserMongo.findById(id);
};

const createUser = async ({ name, email, phone, password, role, ownerId, assignedTurfId, assignedGround }) => {
    if (isPostgres()) {
        const hashedPassword = password.startsWith('$2') ? password : await bcrypt.hash(password, 10);
        const user = await prisma.user.create({
            data: {
                name,
                email: email.toLowerCase().trim(),
                phone: phone.trim(),
                password: hashedPassword,
                role: role || 'customer',
                status: 'active',
                ownerId: ownerId || null,
                assignedTurfId: assignedTurfId || null,
                assignedGround: assignedGround || ''
            }
        });
        return serializeUser(user);
    }

    const user = await UserMongo.create({
        name,
        email,
        phone,
        password,
        role: role || 'customer',
        ownerId,
        assignedTurfId,
        assignedGround
    });
    return user;
};

const matchPassword = async (enteredPassword, storedPassword) => {
    return await bcrypt.compare(enteredPassword, storedPassword);
};

const createRefreshToken = async ({ token, userId, expiryDate }) => {
    if (isPostgres()) {
        return await prisma.refreshToken.create({
            data: {
                token,
                userId: String(userId),
                expiryDate
            }
        });
    }

    const refreshToken = new RefreshTokenMongo({
        token,
        user: userId,
        expiryDate
    });
    return await refreshToken.save();
};

const findRefreshToken = async (token) => {
    if (isPostgres()) {
        const rt = await prisma.refreshToken.findUnique({
            where: { token },
            include: { user: true }
        });
        if (!rt) return null;
        return {
            ...rt,
            _id: rt.id,
            user: serializeUser(rt.user),
            isExpired: () => rt.expiryDate.getTime() <= new Date().getTime()
        };
    }

    return await RefreshTokenMongo.findOne({ token }).populate('user');
};

const deleteRefreshToken = async (tokenOrId) => {
    if (isPostgres()) {
        try {
            return await prisma.refreshToken.delete({
                where: { id: String(tokenOrId) }
            });
        } catch {
            return await prisma.refreshToken.deleteMany({
                where: { token: String(tokenOrId) }
            });
        }
    }

    return await RefreshTokenMongo.findByIdAndDelete(tokenOrId);
};

const updateFCMToken = async (userId, token) => {
    if (isPostgres()) {
        const user = await prisma.user.findUnique({ where: { id: String(userId) } });
        if (!user) return null;
        if (!user.fcmTokens.includes(token)) {
            const updated = await prisma.user.update({
                where: { id: String(userId) },
                data: {
                    fcmTokens: { push: token }
                }
            });
            return serializeUser(updated);
        }
        return serializeUser(user);
    }

    const user = await UserMongo.findById(userId);
    if (!user) return null;
    if (!user.fcmTokens.includes(token)) {
        user.fcmTokens.push(token);
        await user.save();
    }
    return user;
};

const findAllUsers = async () => {
    if (isPostgres()) {
        const users = await prisma.user.findMany({
            orderBy: { createdAt: 'desc' }
        });
        return users.map(serializeUser);
    }
    return await UserMongo.find({}).select('-password');
};

const updateUserStatus = async (id, status) => {
    if (isPostgres()) {
        const user = await prisma.user.update({
            where: { id: String(id) },
            data: { status }
        });
        return serializeUser(user);
    }
    const user = await UserMongo.findById(id);
    if (!user) return null;
    user.status = status;
    return await user.save();
};

const deleteUser = async (id) => {
    if (isPostgres()) {
        return await prisma.user.delete({
            where: { id: String(id) }
        });
    }
    return await UserMongo.findByIdAndDelete(id);
};

module.exports = {
    findByEmailOrPhone,
    findById,
    findAllUsers,
    updateUserStatus,
    deleteUser,
    createUser,
    matchPassword,
    createRefreshToken,
    findRefreshToken,
    deleteRefreshToken,
    updateFCMToken,
    isPostgres
};
