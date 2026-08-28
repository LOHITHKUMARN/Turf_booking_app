const { z } = require('zod');

// Middleware factory: validates req.body against a Zod schema
const validate = (schema) => (req, res, next) => {
    try {
        schema.parse(req.body);
        next();
    } catch (err) {
        const errors = err.errors?.map(e => ({
            field: e.path.join('.'),
            message: e.message,
        })) || [{ field: 'unknown', message: err.message }];

        return res.status(400).json({
            message: 'Validation failed',
            errors,
        });
    }
};

// ──────────────────── Auth Schemas ────────────────────

const registerSchema = z.object({
    name: z.string().min(2, 'Name must be at least 2 characters').max(50),
    email: z.string().email('Invalid email format'),
    phone: z.string().min(10, 'Phone must be at least 10 digits').max(15),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    role: z.enum(['customer', 'owner']).optional(),
});

const loginSchema = z.object({
    email: z.string().optional(),
    phone: z.string().optional(),
    identifier: z.string().optional(),
    password: z.string().min(1, 'Password is required'),
}).refine(data => data.email || data.phone || data.identifier, {
    message: "Email, Phone or Identifier is required",
    path: ["identifier"]
});

const requestPayoutSchema = z.object({
    amount: z.number().min(500, 'Minimum payout is 500'),
    bankDetails: z.object({
        accountNumber: z.string().min(1),
        ifscCode: z.string().min(1),
        accountHolderName: z.string().min(1),
    }).optional(),
});

// ──────────────────── Turf Schemas ────────────────────

const createTurfSchema = z.object({
    name: z.string().min(2).max(100),
    location: z.object({
        city: z.string().min(2),
        area: z.string().min(2),
    }),
    sports: z.array(z.string()).min(1, 'At least one sport is required'),
    amenities: z.array(z.string()).optional().default([]),
    images: z.array(z.string()).optional().default([]),
    grounds: z.array(z.string()).optional().default([]),
    upiId: z.string().optional().default(''),
    taxPercentage: z.number().min(0).max(100).optional().default(0),
    turfType: z.enum(['indoor', 'outdoor', 'both']).optional().default('both'),
});

// ──────────────────── Booking Schemas ────────────────────

const createBookingSchema = z.object({
    turfId: z.string().min(1, 'Turf ID is required'),
    slotId: z.string().min(1, 'Slot ID is required'),
    bookingDate: z.string().min(1, 'Booking date is required'),
    sport: z.string().optional(),
    groundName: z.string().optional().default(''),
    paymentMethod: z.enum(['cash', 'upi']).optional().default('cash'),
});

// ──────────────────── Slot Schemas ────────────────────

const manageSlotsSchema = z.object({
    turfId: z.string().min(1),
    slots: z.array(z.object({
        sport: z.string().min(1),
        groundName: z.string().optional().default(''),
        dayOfWeek: z.enum(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']),
        startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Must be HH:MM format'),
        endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Must be HH:MM format'),
        price: z.number().min(0),
    })).min(1, 'At least one slot is required'),
});

// ──────────────────── Review Schemas ────────────────────

const createReviewSchema = z.object({
    turfId: z.string().min(1),
    bookingId: z.string().min(1),
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(500).optional().default(''),
});

// ──────────────────── Staff Schemas ────────────────────

const createStaffSchema = z.object({
    name: z.string().min(2).max(50),
    email: z.string().email(),
    phone: z.string().min(10).max(15),
    password: z.string().min(6),
});

const reportIncidentSchema = z.object({
    type: z.enum(['Injury', 'Damage', 'Crowd Issue', 'Other']),
    severity: z.enum(['Low', 'Medium', 'High', 'Critical']).optional().default('Low'),
    description: z.string().min(5, 'Description must be at least 5 characters'),
    images: z.array(z.string()).optional().default([]),
});

// ──────────────────── Announcement Schemas ────────────────────

const createAnnouncementSchema = z.object({
    turfId: z.string().min(1),
    title: z.string().min(2).max(100),
    message: z.string().min(2).max(500),
    type: z.enum(['General', 'Emergency', 'Shift Update']).optional().default('General'),
    isPublic: z.boolean().optional().default(false),
});

// ──────────────────── Tournament Schemas ────────────────────

const createTournamentSchema = z.object({
    turfId: z.string().min(1, 'Turf ID is required'),
    name: z.string().min(2, 'Tournament name must be at least 2 characters').max(100),
    description: z.string().min(3, 'Description must be at least 3 characters'),
    sportsType: z.string().min(1, 'Sports type is required'),
    teamSize: z.number().int().min(1),
    maxTeams: z.number().int().min(2),
    registrationFee: z.number().min(0).optional().default(0),
    prizePool: z.string().optional().default(''),
    startDate: z.string().min(1, 'Start date is required'),
    endDate: z.string().min(1, 'End date is required'),
    registrationDeadline: z.string().min(1, 'Registration deadline is required'),
    rules: z.array(z.string()).optional().default([]),
});

const registerTeamSchema = z.object({
    tournamentId: z.string().min(1, 'Tournament ID is required'),
    name: z.string().min(2, 'Team name must be at least 2 characters').max(50),
    members: z.array(z.string()).optional().default([]),
});

const createMatchSchema = z.object({
    tournamentId: z.string().min(1),
    team1Id: z.string().optional(),
    team2Id: z.string().optional(),
    round: z.number().int().min(1),
    matchIndex: z.number().int().min(0),
    startTime: z.string().optional(),
    groundName: z.string().optional().default(''),
});

const updateMatchSchema = z.object({
    startTime: z.string().optional(),
    groundName: z.string().optional(),
    status: z.enum(['scheduled', 'live', 'completed', 'verified', 'cancelled']).optional(),
    score1: z.number().int().min(0).optional(),
    score2: z.number().int().min(0).optional(),
    winnerId: z.string().optional(),
});

const updateMatchScoreSchema = z.object({
    score1: z.number().int().min(0),
    score2: z.number().int().min(0),
    winnerId: z.string().optional(),
    status: z.enum(['scheduled', 'live', 'completed', 'verified']).optional().default('completed'),
});

const joinTeamSchema = z.object({
    teamCode: z.string().min(6, 'Invalid team code'),
});

const updateTournamentSchema = z.object({
    name: z.string().min(2).max(100).optional(),
    description: z.string().min(3).optional(),
    sportsType: z.string().optional(),
    teamSize: z.number().int().min(1).optional(),
    maxTeams: z.number().int().min(2).optional(),
    registrationFee: z.number().min(0).optional(),
    prizePool: z.string().optional(),
    startDate: z.string().optional(),
    endDate: z.string().optional(),
    registrationDeadline: z.string().optional(),
    rules: z.array(z.string()).optional(),
    status: z.enum(['open', 'ongoing', 'completed', 'cancelled', 'draft']).optional(),
});

module.exports = {
    validate,
    registerSchema,
    loginSchema,
    createTurfSchema,
    createBookingSchema,
    manageSlotsSchema,
    createReviewSchema,
    createStaffSchema,
    reportIncidentSchema,
    createAnnouncementSchema,
    createTournamentSchema,
    updateTournamentSchema,
    registerTeamSchema,
    updateMatchScoreSchema,
    createMatchSchema,
    updateMatchSchema,
    joinTeamSchema,
    requestPayoutSchema,
};
