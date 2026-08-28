const express = require('express');
const router = express.Router();
const { protect, loadUser } = require('../middlewares/authMiddleware');
const roleGuard = require('../middlewares/roleGuard');
const { validate, createTournamentSchema, updateTournamentSchema, registerTeamSchema, updateMatchScoreSchema, createMatchSchema, updateMatchSchema } = require('../middlewares/validation');
const {
    createTournament,
    getMyTournaments,
    getTournamentTeams,
    updateTeamStatus,
    getPendingTournaments,
    approveTournament,
    getStaffMatches,
    updateMatchScore,
    getPublicTournaments,
    registerTeam,
    generateFixtures,
    getTournamentById,
    updateTournament,
    getTournamentMatches,
    createMatch,
    updateMatch,
    deleteMatch
} = require('../controllers/tournamentController');

// ──────────────────── Public/Discovery ────────────────────
router.get('/discovery', loadUser, getPublicTournaments);
router.post('/register', protect, roleGuard('customer'), validate(registerTeamSchema), registerTeam);

// ──────────────────── Staff Routes ────────────────────
router.get('/staff/matches', protect, roleGuard('staff'), getStaffMatches);
router.put('/matches/:matchId/score', protect, roleGuard('staff'), validate(updateMatchScoreSchema), updateMatchScore);

// ──────────────────── Admin Routes ────────────────────
router.get('/admin/pending', protect, roleGuard('admin'), getPendingTournaments);
router.put('/admin/approve/:id', protect, roleGuard('admin'), approveTournament);

// ──────────────────── Owner Routes ────────────────────
router.get('/my', protect, roleGuard('owner'), getMyTournaments);
router.post('/', protect, roleGuard('owner'), validate(createTournamentSchema), createTournament);
router.get('/:id/teams', protect, roleGuard('owner'), getTournamentTeams);
router.put('/teams/:teamId/status', protect, roleGuard('owner'), updateTeamStatus);
router.post('/:id/fixtures/generate', protect, roleGuard('owner'), generateFixtures);
router.get('/:id/matches', loadUser, getTournamentMatches);
router.post('/:id/matches', protect, roleGuard('owner'), validate(createMatchSchema), createMatch);
router.put('/matches/:matchId', protect, roleGuard('owner'), validate(updateMatchSchema), updateMatch);
router.delete('/matches/:matchId', protect, roleGuard('owner'), deleteMatch);
router.put('/:id', protect, roleGuard('owner'), validate(updateTournamentSchema), updateTournament);

// ──────────────────── Protected Parameterized Routes (must be after literal routes) ────────────────────
router.get('/:id', loadUser, getTournamentById);

module.exports = router;
