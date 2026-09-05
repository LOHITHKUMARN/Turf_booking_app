const { prisma } = require('../config/db');
const TournamentMongo = require('../models/Tournament');
const TournamentTeamMongo = require('../models/TournamentTeam');
const TournamentMatchMongo = require('../models/TournamentMatch');
const { serializeTournament, serializeTeam, serializeMatch } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findTournaments = async (query = {}) => {
    if (isPostgres()) {
        const where = {};
        if (query.status) where.status = query.status;
        if (query.turfId) where.turfId = String(query.turfId);
        if (query.ownerId) where.ownerId = String(query.ownerId);

        const tournaments = await prisma.tournament.findMany({
            where,
            include: {
                turf: { select: { id: true, name: true, city: true, area: true } },
                owner: { select: { id: true, name: true, phone: true } }
            },
            orderBy: { startDate: 'asc' }
        });
        return tournaments.map(serializeTournament);
    }

    return await TournamentMongo.find(query).populate('turfId', 'name location').sort({ startDate: 1 });
};

const findTournamentById = async (id) => {
    if (!id) return null;
    if (isPostgres()) {
        const tournament = await prisma.tournament.findUnique({
            where: { id: String(id) },
            include: {
                turf: true,
                owner: true,
                teams: {
                    include: { captain: true }
                },
                matches: {
                    include: { team1: true, team2: true, winner: true, staff: true }
                }
            }
        });
        return tournament ? serializeTournament(tournament) : null;
    }

    return await TournamentMongo.findById(id).populate('turfId').populate('ownerId');
};

const createTournament = async (data) => {
    if (isPostgres()) {
        const tournament = await prisma.tournament.create({
            data: {
                ownerId: String(data.ownerId),
                turfId: String(data.turfId),
                name: data.name,
                description: data.description,
                sportsType: data.sportsType,
                teamSize: Number(data.teamSize),
                maxTeams: Number(data.maxTeams),
                registrationFee: Number(data.registrationFee || 0),
                prizePool: data.prizePool !== undefined ? String(data.prizePool) : '',
                startDate: new Date(data.startDate),
                endDate: new Date(data.endDate),
                registrationDeadline: new Date(data.registrationDeadline),
                rules: data.rules || [],
                status: data.status || 'pending_approval',
                adminNotes: data.adminNotes || '',
                bannerImage: data.bannerImage || ''
            }
        });
        return serializeTournament(tournament);
    }

    return await TournamentMongo.create(data);
};

const registerTeam = async (data) => {
    if (isPostgres()) {
        const team = await prisma.tournamentTeam.create({
            data: {
                tournamentId: String(data.tournamentId),
                captainId: String(data.captainId),
                name: data.name,
                members: data.members || [],
                status: 'pending',
                paymentStatus: data.paymentStatus || 'pending',
                transactionId: data.transactionId || ''
            },
            include: { captain: true }
        });
        return serializeTeam(team);
    }

    return await TournamentTeamMongo.create(data);
};

const findTeamsByTournament = async (tournamentId) => {
    if (isPostgres()) {
        const teams = await prisma.tournamentTeam.findMany({
            where: { tournamentId: String(tournamentId) },
            include: { captain: true }
        });
        return teams.map(serializeTeam);
    }

    return await TournamentTeamMongo.find({ tournamentId }).populate('captainId', 'name phone email');
};

const findMatchesByTournament = async (tournamentId) => {
    if (isPostgres()) {
        const matches = await prisma.tournamentMatch.findMany({
            where: { tournamentId: String(tournamentId) },
            include: { team1: true, team2: true, winner: true, staff: true },
            orderBy: [{ round: 'asc' }, { matchIndex: 'asc' }]
        });
        return matches.map(serializeMatch);
    }

    return await TournamentMatchMongo.find({ tournamentId })
        .populate('team1Id')
        .populate('team2Id')
        .populate('winnerId')
        .sort({ round: 1, matchIndex: 1 });
};

const updateMatchScore = async (matchId, { score1, score2, winnerId, status, staffNotes }) => {
    if (isPostgres()) {
        const data = {};
        if (score1 !== undefined) data.score1 = Number(score1);
        if (score2 !== undefined) data.score2 = Number(score2);
        if (winnerId) data.winnerId = String(winnerId);
        if (status) data.status = status;
        if (staffNotes !== undefined) data.staffNotes = staffNotes;

        const match = await prisma.tournamentMatch.update({
            where: { id: String(matchId) },
            data,
            include: { team1: true, team2: true, winner: true }
        });
        return serializeMatch(match);
    }

    return await TournamentMatchMongo.findByIdAndUpdate(matchId, { score1, score2, winnerId, status, staffNotes }, { new: true });
};

module.exports = {
    findTournaments,
    findTournamentById,
    createTournament,
    registerTeam,
    findTeamsByTournament,
    findMatchesByTournament,
    updateMatchScore,
    isPostgres
};
