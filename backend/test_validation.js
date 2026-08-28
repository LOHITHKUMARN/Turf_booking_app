const { z } = require('zod');

const createTournamentSchema = z.object({
    turfId: z.string().min(1, 'Turf ID is required'),
    name: z.string().min(2, 'Tournament name must be at least 2 characters').max(100),
    description: z.string().min(10, 'Description must be at least 10 characters'),
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

const testData = {
    turfId: "65f1a2b3c4d5e6f7a8b9c0d1", // Simulated ID
    sportsType: "Cricket",
    name: "Summer Cup 2026",
    description: "Short",
    teamSize: 5,
    maxTeams: 16,
    registrationFee: 500.0,
    prizePool: "Rs. 10k",
    startDate: new Date().toISOString(),
    endDate: new Date().toISOString(),
    registrationDeadline: new Date().toISOString(),
};

try {
    createTournamentSchema.parse(testData);
    console.log("Validation Passed!");
} catch (err) {
    console.log("Validation Failed:");
    if (err.errors) {
        console.log(JSON.stringify(err.errors, null, 2));
    } else {
        console.error(err);
    }
}
