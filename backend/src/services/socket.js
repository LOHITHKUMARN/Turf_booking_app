const { Server } = require('socket.io');
const logger = require('./logger');

let io = null;

const initSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
    });

    io.on('connection', (socket) => {
        logger.info(`Socket connected: ${socket.id}`);

        // Join turf-specific rooms
        socket.on('joinTurf', (turfId) => {
            socket.join(`turf:${turfId}`);
            logger.info(`Socket ${socket.id} joined room turf:${turfId}`);
        });

        // Join role-specific rooms
        socket.on('joinRole', (role) => {
            socket.join(`role:${role}`);
            logger.info(`Socket ${socket.id} joined room role:${role}`);
        });

        socket.on('disconnect', () => {
            logger.info(`Socket disconnected: ${socket.id}`);
        });
    });

    logger.info('Socket.IO initialized');
    return io;
};

// Emit events to specific turf rooms
const emitToTurf = (turfId, event, data) => {
    if (!io) return;
    io.to(`turf:${turfId}`).emit(event, data);
    logger.info(`Socket event [${event}] emitted to turf:${turfId}`);
};

// Emit events to a role
const emitToRole = (role, event, data) => {
    if (!io) return;
    io.to(`role:${role}`).emit(event, data);
};

// Broadcast to everyone
const emitGlobal = (event, data) => {
    if (!io) return;
    io.emit(event, data);
};

module.exports = { initSocket, emitToTurf, emitToRole, emitGlobal, getIO: () => io };
