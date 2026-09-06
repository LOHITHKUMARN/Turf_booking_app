const Tournament = require('../models/Tournament');
const TournamentTeam = require('../models/TournamentTeam');
const TournamentMatch = require('../models/TournamentMatch');
const Turf = require('../models/Turf');
const User = require('../models/User');
const userRepository = require('../repositories/userRepository');
const tournamentRepository = require('../repositories/tournamentRepository');
const { prisma } = require('../config/db');
const { serializeMatch, serializeTournament, serializeTeam } = require('../utils/serializer');
const { sendToUser, sendToRole } = require('../services/notificationService');
const { emitToRole } = require('../services/socket');
const logger = require('../services/logger');

// ──────────────────── Admin Actions ────────────────────

exports.getPendingTournaments = async (req, res) => {
    try {
        if (tournamentRepository.isPostgres()) {
            const tournaments = await prisma.tournament.findMany({
                where: { status: 'pending_approval' },
                include: {
                    owner: { select: { id: true, name: true, email: true, phone: true } },
                    turf: { select: { id: true, name: true, city: true, area: true } }
                },
                orderBy: { createdAt: 'desc' }
            });
            return res.json(tournaments.map(serializeTournament));
        }

        const tournaments = await Tournament.find({ status: 'pending_approval' })
            .populate('ownerId', 'name email')
            .populate('turfId', 'name location');
        res.json(tournaments);
    } catch (error) {
        logger.error('Error in getPendingTournaments:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.approveTournament = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, adminNotes } = req.body; // status: 'open' or 'rejected'

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.update({
                where: { id: String(id) },
                data: {
                    status: status === 'open' ? 'open' : 'rejected',
                    adminNotes: adminNotes || ''
                },
                include: { owner: true, turf: true }
            });

            if (tournament.owner) {
                await sendToUser(tournament.owner, {
                    title: `Tournament ${status === 'open' ? 'Approved' : 'Rejected'}`,
                    body: `Your tournament "${tournament.name}" has been ${status}. ${adminNotes || ''}`,
                    data: { type: 'tournament_approval', tournamentId: tournament.id }
                });
            }

            return res.json({ message: `Tournament ${status} successfully`, tournament: serializeTournament(tournament) });
        }

        const tournament = await Tournament.findByIdAndUpdate(
            id,
            { status, adminNotes },
            { new: true }
        );

        if (!tournament) return res.status(404).json({ message: 'Tournament not found' });

        // Notify owner
        const owner = await User.findById(tournament.ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: `Tournament ${status === 'open' ? 'Approved' : 'Rejected'}`,
                body: `Your tournament "${tournament.name}" has been ${status}. ${adminNotes || ''}`,
                data: { type: 'tournament_approval', tournamentId: tournament._id.toString() }
            });
        }

        res.json({ message: `Tournament ${status} successfully`, tournament });
    } catch (error) {
        logger.error('Error in approveTournament:', error);
        res.status(500).json({ message: error.message });
    }
};

// ──────────────────── Owner Actions ────────────────────

exports.createTournament = async (req, res) => {
    try {
        logger.info(`Creating tournament with body: ${JSON.stringify(req.body, null, 2)}`);
        const ownerId = req.user._id || req.user.id;
        const tournamentData = {
            ...req.body,
            ownerId: String(ownerId),
            prizePool: req.body.prizePool !== undefined ? String(req.body.prizePool) : '',
            status: req.body.status || 'open' // Fully decided by owner, default 'open'
        };

        if (tournamentRepository.isPostgres()) {
            const tournament = await tournamentRepository.createTournament(tournamentData);
            logger.info(`Tournament saved successfully via Prisma: ${tournament.id}`);
            return res.status(201).json({ message: 'Tournament created successfully', tournament });
        }

        const tournament = new Tournament(tournamentData);
        await tournament.save();
        logger.info(`Tournament saved successfully via Mongoose: ${tournament._id}`);

        res.status(201).json({ message: 'Tournament created successfully', tournament });
    } catch (error) {
        logger.error('Error in createTournament:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getMyTournaments = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        logger.info(`Fetching tournaments for owner: ${ownerId}`);

        if (tournamentRepository.isPostgres()) {
            const tournaments = await prisma.tournament.findMany({
                where: { ownerId: String(ownerId) },
                include: {
                    turf: {
                        select: {
                            id: true,
                            name: true,
                            city: true,
                            area: true,
                            images: true
                        }
                    },
                    _count: {
                        select: { teams: true }
                    }
                },
                orderBy: { createdAt: 'desc' }
            });

            const now = new Date();
            const result = [];
            for (let t of tournaments) {
                if (t.status === 'ongoing' && new Date(t.startDate) > now) {
                    await prisma.tournament.update({
                        where: { id: t.id },
                        data: { status: 'open' }
                    });
                    t.status = 'open';
                }
                const serialized = serializeTournament(t);
                serialized.registeredTeamsCount = t._count ? t._count.teams : 0;
                result.push(serialized);
            }
            logger.info(`Found ${result.length} tournaments for owner (Postgres)`);
            return res.json(result);
        }

        const tournaments = await Tournament.find({ ownerId: req.user._id })
            .populate('turfId', 'name location');
        
        // --- Self-Repair: Correct 'ongoing' status if startDate is in the future ---
        const now = new Date();
        for (let t of tournaments) {
            if (t.status === 'ongoing' && new Date(t.startDate) > now) {
                t.status = 'open';
                await t.save();
            }
        }

        const tournamentsWithCounts = await Promise.all(tournaments.map(async (t) => {
            const count = await TournamentTeam.countDocuments({ tournamentId: t._id });
            return { ...t.toObject(), registeredTeamsCount: count };
        }));

        logger.info(`Found ${tournaments.length} tournaments`);
        res.json(tournamentsWithCounts);
    } catch (error) {
        logger.error('Error in getMyTournaments:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getTournamentTeams = async (req, res) => {
    try {
        if (tournamentRepository.isPostgres()) {
            const teams = await prisma.tournamentTeam.findMany({
                where: { tournamentId: String(req.params.id) },
                include: {
                    captain: { select: { id: true, name: true, email: true, phone: true } }
                },
                orderBy: { createdAt: 'asc' }
            });
            return res.json(teams.map(serializeTeam));
        }

        const teams = await TournamentTeam.find({ tournamentId: req.params.id })
            .populate('captainId', 'name email phone');
        res.json(teams);
    } catch (error) {
        logger.error('Error in getTournamentTeams:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateTeamStatus = async (req, res) => {
    try {
        const { teamId } = req.params;
        const { status } = req.body; // 'approved' or 'rejected'

        if (tournamentRepository.isPostgres()) {
            const team = await prisma.tournamentTeam.update({
                where: { id: String(teamId) },
                data: { status: status === 'approved' ? 'approved' : 'rejected' },
                include: { captain: true, tournament: true }
            });

            if (team.captain) {
                await sendToUser(team.captain, {
                    title: `Team ${status === 'approved' ? 'Accepted' : 'Rejected'}`,
                    body: `Your team "${team.name}" has been ${status} for the tournament "${team.tournament?.name || ''}".`,
                    data: { type: 'team_status', tournamentId: team.tournamentId }
                });
            }

            emitToRole('customer', 'team_status_updated', {
                tournamentId: team.tournamentId,
                teamId: team.id,
                status: status
            });

            return res.json({ message: `Team ${status} successfully`, team: serializeTeam(team) });
        }

        const team = await TournamentTeam.findByIdAndUpdate(teamId, { status }, { new: true });
        if (!team) return res.status(404).json({ message: 'Team not found' });

        // Notify captain
        const captain = await User.findById(team.captainId);
        if (captain) {
            const tournament = await Tournament.findById(team.tournamentId);
            await sendToUser(captain, {
                title: `Team ${status === 'approved' ? 'Accepted' : 'Rejected'}`,
                body: `Your team "${team.name}" has been ${status} for the tournament "${tournament.name}".`,
                data: { type: 'team_status', tournamentId: tournament._id.toString() }
            });
        }

        // Notify captain via Socket
        emitToRole('customer', 'team_status_updated', {
            tournamentId: team.tournamentId,
            teamId: team._id,
            status: status
        });

        res.json({ message: `Team ${status} successfully`, team });
    } catch (error) {
        logger.error('Error in updateTeamStatus:', error);
        res.status(500).json({ message: error.message });
    }
};

// ──────────────────── Staff Actions ────────────────────

exports.getStaffMatches = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = staff?.assignedTurfId ? (staff.assignedTurfId._id || staff.assignedTurfId.id || staff.assignedTurfId) : null;
        if (!staff || !turfId) {
            logger.info(`Staff user ${userId} has no assigned turf`);
            return res.json([]);
        }

        if (tournamentRepository.isPostgres()) {
            const matches = await prisma.tournamentMatch.findMany({
                where: {
                    tournament: { turfId: String(turfId) },
                    status: { in: ['scheduled', 'live'] }
                },
                include: {
                    team1: true,
                    team2: true,
                    tournament: true
                }
            });
            logger.info(`Found ${matches.length} matches for staff (Postgres)`);
            return res.json(matches.map(serializeMatch));
        }

        // Find tournaments for this turf
        const tournaments = await Tournament.find({ turfId: turfId });
        const tournamentIds = tournaments.map(t => t._id);

        logger.info(`Fetching staff matches for turf: ${turfId}, Tournaments: ${tournamentIds.length}`);

        const matches = await TournamentMatch.find({
            tournamentId: { $in: tournamentIds },
            status: { $in: ['scheduled', 'live'] }
        })
        .populate('team1Id', 'name')
        .populate('team2Id', 'name')
        .populate('tournamentId', 'name turfId');
        
        logger.info(`Found ${matches.length} matches for staff`);
        res.json(matches);
    } catch (error) {
        logger.error('Error in getStaffMatches:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateMatchScore = async (req, res) => {
    try {
        const { matchId } = req.params;
        const { score1, score2, winnerId, status } = req.body;
        const staffId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const updated = await prisma.tournamentMatch.update({
                where: { id: String(matchId) },
                data: {
                    score1: Number(score1),
                    score2: Number(score2),
                    winnerId: winnerId ? String(winnerId) : null,
                    status: status || 'completed',
                    isVerified: true,
                    staffId: String(staffId)
                },
                include: { team1: true, team2: true, winner: true, staff: true }
            });
            return res.json({ message: 'Match score updated and verified', match: serializeMatch(updated) });
        }

        const match = await TournamentMatch.findByIdAndUpdate(
            matchId,
            { score1, score2, winnerId, status, isVerified: true, staffId: req.user._id },
            { new: true }
        );

        if (!match) return res.status(404).json({ message: 'Match not found' });

        res.json({ message: 'Match score updated and verified', match });
    } catch (error) {
        logger.error('Error in updateMatchScore:', error);
        res.status(500).json({ message: error.message });
    }
};

// ──────────────────── Customer Actions ────────────────────

exports.getPublicTournaments = async (req, res) => {
    try {
        const { sport, city, date } = req.query;
        const currentUserId = req.user ? (req.user._id || req.user.id) : null;

        if (tournamentRepository.isPostgres()) {
            const where = {
                status: { in: ['open', 'ongoing'] }
            };
            if (sport) where.sportsType = sport;
            if (date) where.startDate = { gte: new Date(date) };
            if (city) {
                where.turf = {
                    city: { equals: city, mode: 'insensitive' }
                };
            }

            const tournaments = await prisma.tournament.findMany({
                where,
                include: {
                    turf: {
                        select: {
                            id: true,
                            name: true,
                            city: true,
                            area: true,
                            images: true
                        }
                    },
                    teams: currentUserId ? {
                        where: { captainId: String(currentUserId) },
                        select: { id: true }
                    } : false,
                    _count: {
                        select: { teams: true }
                    }
                },
                orderBy: { startDate: 'asc' }
            });

            const now = new Date();
            const result = [];
            for (let t of tournaments) {
                if (t.status === 'ongoing' && new Date(t.startDate) > now) {
                    await prisma.tournament.update({
                        where: { id: t.id },
                        data: { status: 'open' }
                    });
                    t.status = 'open';
                }
                const serialized = serializeTournament(t);
                serialized.registeredTeamsCount = t._count ? t._count.teams : 0;
                serialized.isRegistered = currentUserId && t.teams ? t.teams.length > 0 : false;
                result.push(serialized);
            }

            logger.info(`Returning ${result.length} public tournaments (Postgres)`);
            return res.json(result);
        }

        // Search for both 'open' and 'ongoing' to catch ones that might need repair
        let query = { status: { $in: ['open', 'ongoing'] } };

        if (sport) query.sportsType = sport;
        if (date) query.startDate = { $gte: new Date(date) };
        logger.info(`Getting public tournaments. Query: ${JSON.stringify(query)}`);
        let tournaments = await Tournament.find(query)
            .populate('turfId', 'name location images');

        logger.info(`Found ${tournaments.length} tournaments before city filter`);

        // --- Self-Repair: Correct 'ongoing' status if startDate is in the future ---
        const now = new Date();
        let repairCount = 0;
        for (let t of tournaments) {
            if (t.status === 'ongoing' && new Date(t.startDate) > now) {
                t.status = 'open';
                await t.save();
                repairCount++;
            }
        }
        if (repairCount > 0) logger.info(`Repaired ${repairCount} tournament statuses`);

        if (city) {
            const beforeFilter = tournaments.length;
            tournaments = tournaments.filter(t => t.turfId && t.turfId.location && t.turfId.location.city && t.turfId.location.city.toLowerCase() === city.toLowerCase());
            logger.info(`City filter (${city}) reduced tournaments from ${beforeFilter} to ${tournaments.length}`);
        }

        const tournamentsWithCounts = await Promise.all(tournaments.map(async (t) => {
            const count = await TournamentTeam.countDocuments({ tournamentId: t._id });
            let isRegistered = false;
            if (req.user) {
                const team = await TournamentTeam.findOne({ tournamentId: t._id, captainId: req.user._id });
                isRegistered = !!team;
            }
            return { ...t.toObject(), registeredTeamsCount: count, isRegistered };
        }));

        logger.info(`Returning ${tournamentsWithCounts.length} public tournaments`);
        res.json(tournamentsWithCounts);
    } catch (error) {
        logger.error('Error in getPublicTournaments:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getTournamentById = async (req, res) => {
    try {
        const { id } = req.params;
        const currentUserId = req.user ? (req.user._id || req.user.id) : null;

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.findUnique({
                where: { id: String(id) },
                include: {
                    turf: {
                        select: {
                            id: true,
                            name: true,
                            city: true,
                            area: true,
                            images: true
                        }
                    },
                    owner: { select: { id: true, name: true, phone: true, email: true } },
                    teams: currentUserId ? {
                        where: { captainId: String(currentUserId) },
                        select: { id: true }
                    } : false,
                    _count: {
                        select: { teams: true }
                    }
                }
            });

            if (!tournament) return res.status(404).json({ message: 'Tournament not found' });

            const serialized = serializeTournament(tournament);
            serialized.registeredTeamsCount = tournament._count ? tournament._count.teams : 0;
            serialized.isRegistered = currentUserId && tournament.teams ? tournament.teams.length > 0 : false;
            return res.json(serialized);
        }

        const tournament = await Tournament.findById(req.params.id).populate('turfId');
        if (!tournament) return res.status(404).json({ message: 'Tournament not found' });
        
        const count = await TournamentTeam.countDocuments({ tournamentId: tournament._id });
        let isRegistered = false;
        if (req.user) {
            const team = await TournamentTeam.findOne({ tournamentId: tournament._id, captainId: req.user._id });
            isRegistered = !!team;
        }
        res.json({ ...tournament.toObject(), registeredTeamsCount: count, isRegistered });
    } catch (error) {
        logger.error('Error in getTournamentById:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getTournamentMatches = async (req, res) => {
    try {
        const { id } = req.params;

        if (tournamentRepository.isPostgres()) {
            const matches = await prisma.tournamentMatch.findMany({
                where: { tournamentId: String(id) },
                include: {
                    team1: true,
                    team2: true,
                    winner: true,
                    staff: { select: { id: true, name: true, phone: true } }
                },
                orderBy: [{ round: 'asc' }, { matchIndex: 'asc' }]
            });
            return res.json(matches.map(serializeMatch));
        }

        const matches = await TournamentMatch.find({ tournamentId: id })
            .populate('team1Id', 'name')
            .populate('team2Id', 'name')
            .sort({ round: 1, matchIndex: 1 });
        res.json(matches);
    } catch (error) {
        logger.error('Error in getTournamentMatches:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.createMatch = async (req, res) => {
    try {
        const { tournamentId, team1Id, team2Id, round, matchIndex, startTime, groundName } = req.body;
        const currentUserId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.findUnique({
                where: { id: String(tournamentId) }
            });
            if (!tournament) return res.status(404).json({ message: 'Tournament not found' });

            if (tournament.ownerId !== String(currentUserId) && req.user.role !== 'admin') {
                return res.status(403).json({ message: 'Not authorized' });
            }

            const match = await prisma.tournamentMatch.create({
                data: {
                    tournamentId: String(tournamentId),
                    team1Id: team1Id ? String(team1Id) : null,
                    team2Id: team2Id ? String(team2Id) : null,
                    round: Number(round),
                    matchIndex: Number(matchIndex),
                    startTime: startTime ? new Date(startTime) : null,
                    groundName: groundName || '',
                    status: 'scheduled'
                },
                include: { team1: true, team2: true, winner: true }
            });

            return res.status(201).json(serializeMatch(match));
        }

        const tournament = await Tournament.findById(tournamentId);
        if (!tournament) return res.status(404).json({ message: 'Tournament not found' });
        
        // Authorization check
        if (tournament.ownerId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Not authorized' });
        }

        const match = new TournamentMatch({
            tournamentId,
            team1Id,
            team2Id,
            round,
            matchIndex,
            startTime,
            groundName,
            status: 'scheduled'
        });

        await match.save();
        res.status(201).json(match);
    } catch (error) {
        logger.error('Error in createMatch:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateMatch = async (req, res) => {
    try {
        const { matchId } = req.params;
        const currentUserId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const match = await prisma.tournamentMatch.findUnique({
                where: { id: String(matchId) },
                include: { tournament: true }
            });
            if (!match) return res.status(404).json({ message: 'Match not found' });

            if (match.tournament.ownerId !== String(currentUserId) && req.user.role !== 'admin') {
                return res.status(403).json({ message: 'Not authorized' });
            }

            const updateData = {};
            if (req.body.score1 !== undefined) updateData.score1 = Number(req.body.score1);
            if (req.body.score2 !== undefined) updateData.score2 = Number(req.body.score2);
            if (req.body.winnerId !== undefined) updateData.winnerId = req.body.winnerId ? String(req.body.winnerId) : null;
            if (req.body.team1Id !== undefined) updateData.team1Id = req.body.team1Id ? String(req.body.team1Id) : null;
            if (req.body.team2Id !== undefined) updateData.team2Id = req.body.team2Id ? String(req.body.team2Id) : null;
            if (req.body.status !== undefined) updateData.status = req.body.status;
            if (req.body.startTime !== undefined) updateData.startTime = req.body.startTime ? new Date(req.body.startTime) : null;
            if (req.body.groundName !== undefined) updateData.groundName = req.body.groundName;
            if (req.body.isVerified !== undefined) updateData.isVerified = Boolean(req.body.isVerified);
            if (req.body.staffNotes !== undefined) updateData.staffNotes = req.body.staffNotes;

            const updated = await prisma.tournamentMatch.update({
                where: { id: String(matchId) },
                data: updateData,
                include: { team1: true, team2: true, winner: true, staff: true }
            });

            return res.json(serializeMatch(updated));
        }

        const match = await TournamentMatch.findById(matchId);
        if (!match) return res.status(404).json({ message: 'Match not found' });

        const tournament = await Tournament.findById(match.tournamentId);
        // Authorization check
        if (tournament.ownerId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Not authorized' });
        }

        const updatedMatch = await TournamentMatch.findByIdAndUpdate(
            matchId,
            { $set: req.body },
            { new: true }
        ).populate('team1Id team2Id');

        res.json(updatedMatch);
    } catch (error) {
        logger.error('Error in updateMatch:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.deleteMatch = async (req, res) => {
    try {
        const { matchId } = req.params;
        const currentUserId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const match = await prisma.tournamentMatch.findUnique({
                where: { id: String(matchId) },
                include: { tournament: true }
            });
            if (!match) return res.status(404).json({ message: 'Match not found' });

            if (match.tournament.ownerId !== String(currentUserId) && req.user.role !== 'admin') {
                return res.status(403).json({ message: 'Not authorized' });
            }

            await prisma.tournamentMatch.delete({
                where: { id: String(matchId) }
            });

            return res.json({ message: 'Match deleted successfully' });
        }

        const match = await TournamentMatch.findById(matchId);
        if (!match) return res.status(404).json({ message: 'Match not found' });

        const tournament = await Tournament.findById(match.tournamentId);
        // Authorization check
        if (tournament.ownerId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Not authorized' });
        }

        await TournamentMatch.findByIdAndDelete(matchId);
        res.json({ message: 'Match deleted successfully' });
    } catch (error) {
        logger.error('Error in deleteMatch:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.registerTeam = async (req, res) => {
    try {
        const { tournamentId, name, members } = req.body;
        const captainId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.findUnique({
                where: { id: String(tournamentId) }
            });
            if (!tournament || tournament.status !== 'open') {
                return res.status(400).json({ message: 'Tournament is not open for registration' });
            }

            const existingTeam = await prisma.tournamentTeam.findFirst({
                where: {
                    tournamentId: String(tournamentId),
                    captainId: String(captainId)
                }
            });
            if (existingTeam) {
                return res.status(400).json({ message: 'You have already registered a team for this tournament' });
            }

            const team = await prisma.tournamentTeam.create({
                data: {
                    tournamentId: String(tournamentId),
                    captainId: String(captainId),
                    name,
                    members: Array.isArray(members) ? members : [],
                    status: 'pending',
                    paymentStatus: tournament.registrationFee > 0 ? 'pending' : 'paid'
                },
                include: { captain: true }
            });

            logger.info(`Team ${team.name} registered for tournament ${tournamentId}`);

            // Notify owner via Socket
            emitToRole('owner', 'new_registration', {
                tournamentId: tournament.id,
                tournamentName: tournament.name,
                teamId: team.id,
                teamName: team.name
            });

            // Notify owner via Push
            const owner = await prisma.user.findUnique({
                where: { id: tournament.ownerId }
            });
            if (owner) {
                await sendToUser(owner, {
                    title: 'New Team Registration',
                    body: `A new team "${name}" has registered for your tournament "${tournament.name}".`,
                    data: {
                        type: 'new_registration',
                        tournamentId: tournament.id,
                        teamId: team.id
                    }
                });
            }

            return res.status(201).json({ message: 'Team registered successfully', team: serializeTeam(team) });
        }

        // Check if tournament exists and is open
        const tournament = await Tournament.findById(tournamentId);
        if (!tournament || tournament.status !== 'open') {
            return res.status(400).json({ message: 'Tournament is not open for registration' });
        }

        // Check if already registered
        const existingTeam = await TournamentTeam.findOne({ tournamentId, captainId: req.user._id });
        if (existingTeam) {
            return res.status(400).json({ message: 'You have already registered a team for this tournament' });
        }

        const team = new TournamentTeam({
            tournamentId,
            captainId: req.user._id,
            name,
            members,
            status: 'pending',
            paymentStatus: tournament.registrationFee > 0 ? 'pending' : 'paid'
        });

        await team.save();
        logger.info(`Team ${team.name} registered for tournament ${tournamentId}`);

        // Notify Owner via Socket
        emitToRole('owner', 'new_registration', {
            tournamentId: tournament._id,
            tournamentName: tournament.name,
            teamId: team._id,
            teamName: team.name
        });

        // Notify Owner via Push Notification
        const owner = await User.findById(tournament.ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: 'New Team Registration',
                body: `A new team "${name}" has registered for your tournament "${tournament.name}".`,
                data: { 
                    type: 'new_registration', 
                    tournamentId: tournament._id.toString(),
                    teamId: team._id.toString()
                }
            });
        }

        res.status(201).json({ message: 'Team registered successfully', team });
    } catch (error) {
        logger.error('Error in registerTeam:', error);
        res.status(500).json({ message: error.message });
    }
};

// ──────────────────── Fixture Generation Logic ────────────────────

exports.generateFixtures = async (req, res) => {
    try {
        const { id } = req.params;

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.findUnique({
                where: { id: String(id) }
            });
            if (!tournament) return res.status(404).json({ message: 'Tournament not found' });

            const approvedTeams = await prisma.tournamentTeam.findMany({
                where: { tournamentId: String(id), status: 'approved' }
            });

            if (approvedTeams.length < 2) {
                return res.status(400).json({ message: 'At least 2 approved teams are required to generate fixtures' });
            }

            // Shuffle teams
            const shuffledTeams = [...approvedTeams].sort(() => 0.5 - Math.random());

            // Delete existing fixtures if any
            await prisma.tournamentMatch.deleteMany({
                where: { tournamentId: String(id) }
            });

            const matchesToCreate = [];
            for (let i = 0; i < shuffledTeams.length; i += 2) {
                const team1 = shuffledTeams[i];
                const team2 = shuffledTeams[i + 1] || null;

                matchesToCreate.push({
                    tournamentId: String(id),
                    team1Id: team1.id,
                    team2Id: team2 ? team2.id : null,
                    round: 1,
                    matchIndex: Math.floor(i / 2),
                    status: team2 ? 'scheduled' : 'completed',
                    winnerId: team2 ? null : team1.id
                });
            }

            await prisma.tournamentMatch.createMany({
                data: matchesToCreate
            });

            const createdMatches = await prisma.tournamentMatch.findMany({
                where: { tournamentId: String(id) },
                include: { team1: true, team2: true, winner: true },
                orderBy: [{ round: 'asc' }, { matchIndex: 'asc' }]
            });

            const now = new Date();
            let newStatus = tournament.status;
            if (now >= tournament.startDate) {
                newStatus = 'ongoing';
            } else if (tournament.status !== 'pending_approval') {
                newStatus = 'open';
            }

            if (newStatus !== tournament.status) {
                await prisma.tournament.update({
                    where: { id: String(id) },
                    data: { status: newStatus }
                });
            }

            return res.json({ message: 'Fixtures generated successfully', matches: createdMatches.map(serializeMatch) });
        }

        const tournament = await Tournament.findById(id);
        if (!tournament) return res.status(404).json({ message: 'Tournament not found' });

        const approvedTeams = await TournamentTeam.find({ tournamentId: id, status: 'approved' });
        
        if (approvedTeams.length < 2) {
            return res.status(400).json({ message: 'At least 2 approved teams are required to generate fixtures' });
        }

        // Shuffle teams
        const shuffledTeams = approvedTeams.sort(() => 0.5 - Math.random());

        // Delete existing fixtures if any
        await TournamentMatch.deleteMany({ tournamentId: id });

        const matches = [];
        // Simple Round 1 generation
        for (let i = 0; i < shuffledTeams.length; i += 2) {
            const match = new TournamentMatch({
                tournamentId: id,
                team1Id: shuffledTeams[i]._id,
                team2Id: shuffledTeams[i + 1] ? shuffledTeams[i + 1]._id : null, // Bye if odd
                round: 1,
                matchIndex: Math.floor(i / 2),
                status: shuffledTeams[i + 1] ? 'scheduled' : 'completed',
                winnerId: shuffledTeams[i + 1] ? null : shuffledTeams[i]._id
            });
            matches.push(await match.save());
        }

        // Only set to ongoing if the tournament has actually started
        const now = new Date();
        if (now >= tournament.startDate) {
            tournament.status = 'ongoing';
        } else if (tournament.status === 'pending_approval') {
             // Keep as is or transition to open if approved
        } else {
            // Keep it as 'open' if it hasn't started yet
            tournament.status = 'open';
        }
        await tournament.save();

        res.json({ message: 'Fixtures generated successfully', matches });
    } catch (error) {
        logger.error('Error in generateFixtures:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update tournament
// @route   PUT /api/tournaments/:id
// @access  Private (Owner)
exports.updateTournament = async (req, res) => {
    try {
        const { id } = req.params;
        const currentUserId = req.user._id || req.user.id;

        if (tournamentRepository.isPostgres()) {
            const tournament = await prisma.tournament.findUnique({
                where: { id: String(id) }
            });

            if (!tournament) {
                return res.status(404).json({ message: 'Tournament not found' });
            }

            if (tournament.ownerId !== String(currentUserId) && req.user.role !== 'admin') {
                return res.status(403).json({ message: 'Not authorized' });
            }

            if (tournament.status === 'completed') {
                return res.status(400).json({ message: 'Cannot edit a completed tournament' });
            }

            const updateData = {};
            if (req.body.name !== undefined) updateData.name = req.body.name;
            if (req.body.description !== undefined) updateData.description = req.body.description;
            if (req.body.sportsType !== undefined) updateData.sportsType = req.body.sportsType;
            if (req.body.teamSize !== undefined) updateData.teamSize = Number(req.body.teamSize);
            if (req.body.maxTeams !== undefined) updateData.maxTeams = Number(req.body.maxTeams);
            if (req.body.registrationFee !== undefined) updateData.registrationFee = Number(req.body.registrationFee);
            if (req.body.prizePool !== undefined) updateData.prizePool = String(req.body.prizePool);
            if (req.body.startDate !== undefined) updateData.startDate = new Date(req.body.startDate);
            if (req.body.endDate !== undefined) updateData.endDate = new Date(req.body.endDate);
            if (req.body.registrationDeadline !== undefined) updateData.registrationDeadline = new Date(req.body.registrationDeadline);
            if (req.body.rules !== undefined) updateData.rules = Array.isArray(req.body.rules) ? req.body.rules : [];
            if (req.body.bannerImage !== undefined) updateData.bannerImage = req.body.bannerImage;
            if (req.body.status !== undefined) updateData.status = req.body.status;

            const updatedTournament = await prisma.tournament.update({
                where: { id: String(id) },
                data: updateData,
                include: { turf: true, owner: true }
            });

            return res.json(serializeTournament(updatedTournament));
        }

        const tournament = await Tournament.findById(req.params.id);

        if (!tournament) {
            return res.status(404).json({ message: 'Tournament not found' });
        }

        // Check ownership
        if (tournament.ownerId.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        // Only allow editing if not completed
        if (tournament.status === 'completed') {
            return res.status(400).json({ message: 'Cannot edit a completed tournament' });
        }

        const updatedTournament = await Tournament.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true, runValidators: true }
        );

        res.json(updatedTournament);
    } catch (error) {
        logger.error('Error in updateTournament:', error);
        res.status(500).json({ message: error.message });
    }
};
