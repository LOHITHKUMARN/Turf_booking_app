-- CreateEnum
CREATE TYPE "Role" AS ENUM ('customer', 'staff', 'owner', 'admin');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('active', 'blocked');

-- CreateEnum
CREATE TYPE "TurfType" AS ENUM ('indoor', 'outdoor', 'both');

-- CreateEnum
CREATE TYPE "TurfStatus" AS ENUM ('pending', 'approved', 'suspended', 'blocked');

-- CreateEnum
CREATE TYPE "OperationalStatus" AS ENUM ('normal', 'wet', 'maintenance', 'power-issue', 'heavy-rain');

-- CreateEnum
CREATE TYPE "DayOfWeek" AS ENUM ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('cash', 'upi');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('pending', 'paid', 'failed', 'refunded');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('confirmed', 'cancelled', 'completed', 'checked-in', 'no-show');

-- CreateEnum
CREATE TYPE "TournamentStatus" AS ENUM ('pending_approval', 'draft', 'open', 'ongoing', 'completed', 'cancelled', 'rejected');

-- CreateEnum
CREATE TYPE "TeamStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "MatchStatus" AS ENUM ('scheduled', 'live', 'completed', 'verified', 'cancelled');

-- CreateEnum
CREATE TYPE "PayoutStatus" AS ENUM ('pending', 'processed', 'failed');

-- CreateEnum
CREATE TYPE "AnnouncementType" AS ENUM ('General', 'Emergency', 'Shift Update');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('Present', 'Late');

-- CreateEnum
CREATE TYPE "MaintenanceCategory" AS ENUM ('Ground', 'Lights', 'Amenities', 'Other');

-- CreateEnum
CREATE TYPE "MaintenanceStatus" AS ENUM ('Pending', 'In Progress', 'Resolved');

-- CreateEnum
CREATE TYPE "IncidentType" AS ENUM ('Injury', 'Damage', 'Crowd Issue', 'Other');

-- CreateEnum
CREATE TYPE "IncidentSeverity" AS ENUM ('Low', 'Medium', 'High', 'Critical');

-- CreateEnum
CREATE TYPE "IncidentStatus" AS ENUM ('Reported', 'Under Investigation', 'Resolved');

-- CreateEnum
CREATE TYPE "AuditTargetType" AS ENUM ('Turf', 'User', 'System', 'Payout');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'customer',
    "status" "UserStatus" NOT NULL DEFAULT 'active',
    "ownerId" TEXT,
    "assignedTurfId" TEXT,
    "assignedGround" TEXT NOT NULL DEFAULT '',
    "profileImage" TEXT NOT NULL DEFAULT '',
    "fcmTokens" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Turf" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "turfType" "TurfType" NOT NULL DEFAULT 'both',
    "city" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "grounds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "sports" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "amenities" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "TurfStatus" NOT NULL DEFAULT 'pending',
    "operationalStatus" "OperationalStatus" NOT NULL DEFAULT 'normal',
    "minBookingDuration" INTEGER NOT NULL DEFAULT 1,
    "advanceBookingLimit" INTEGER NOT NULL DEFAULT 7,
    "bookingCutoffTime" INTEGER NOT NULL DEFAULT 2,
    "gracePeriod" INTEGER NOT NULL DEFAULT 15,
    "maxMembers" INTEGER NOT NULL DEFAULT 10,
    "upiId" TEXT NOT NULL DEFAULT '',
    "taxPercentage" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "avgRating" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "numReviews" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Turf_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Slot" (
    "id" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "sport" TEXT NOT NULL,
    "groundName" TEXT NOT NULL DEFAULT '',
    "dayOfWeek" "DayOfWeek" NOT NULL,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "isBlocked" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Slot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "turfId" TEXT NOT NULL,
    "slotId" TEXT NOT NULL,
    "groundName" TEXT NOT NULL DEFAULT '',
    "bookingDate" TIMESTAMP(3) NOT NULL,
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "taxAmount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "paymentMethod" "PaymentMethod" NOT NULL DEFAULT 'cash',
    "isPaid" BOOLEAN NOT NULL DEFAULT false,
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'pending',
    "paymentId" TEXT,
    "bookingStatus" "BookingStatus" NOT NULL DEFAULT 'confirmed',
    "transactionId" TEXT,
    "checkInTime" TIMESTAMP(3),
    "checkOutTime" TIMESTAMP(3),
    "staffNotes" TEXT NOT NULL DEFAULT '',
    "isOverstayed" BOOLEAN NOT NULL DEFAULT false,
    "extraCharges" JSONB NOT NULL DEFAULT '[]',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tournament" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "sportsType" TEXT NOT NULL,
    "teamSize" INTEGER NOT NULL,
    "maxTeams" INTEGER NOT NULL,
    "registrationFee" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "prizePool" TEXT NOT NULL DEFAULT '',
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "registrationDeadline" TIMESTAMP(3) NOT NULL,
    "rules" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "TournamentStatus" NOT NULL DEFAULT 'pending_approval',
    "adminNotes" TEXT NOT NULL DEFAULT '',
    "bannerImage" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Tournament_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentTeam" (
    "id" TEXT NOT NULL,
    "tournamentId" TEXT NOT NULL,
    "captainId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "members" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "TeamStatus" NOT NULL DEFAULT 'pending',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'pending',
    "transactionId" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TournamentTeam_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentMatch" (
    "id" TEXT NOT NULL,
    "tournamentId" TEXT NOT NULL,
    "team1Id" TEXT,
    "team2Id" TEXT,
    "winnerId" TEXT,
    "score1" INTEGER NOT NULL DEFAULT 0,
    "score2" INTEGER NOT NULL DEFAULT 0,
    "round" INTEGER NOT NULL,
    "matchIndex" INTEGER NOT NULL,
    "startTime" TIMESTAMP(3),
    "groundName" TEXT NOT NULL DEFAULT '',
    "staffId" TEXT,
    "isVerified" BOOLEAN NOT NULL DEFAULT false,
    "staffNotes" TEXT NOT NULL DEFAULT '',
    "status" "MatchStatus" NOT NULL DEFAULT 'scheduled',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TournamentMatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payout" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" "PayoutStatus" NOT NULL DEFAULT 'pending',
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP(3),
    "bankDetails" JSONB,
    "statementUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Announcement" (
    "id" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" "AnnouncementType" NOT NULL DEFAULT 'General',
    "isPublic" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Announcement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Attendance" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "groundName" TEXT NOT NULL DEFAULT '',
    "clockIn" TIMESTAMP(3) NOT NULL,
    "clockOut" TIMESTAMP(3),
    "status" "AttendanceStatus" NOT NULL DEFAULT 'Present',
    "workHours" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Attendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Maintenance" (
    "id" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "category" "MaintenanceCategory" NOT NULL,
    "description" TEXT NOT NULL,
    "images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "MaintenanceStatus" NOT NULL DEFAULT 'Pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Maintenance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Incident" (
    "id" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "type" "IncidentType" NOT NULL,
    "severity" "IncidentSeverity" NOT NULL DEFAULT 'Low',
    "description" TEXT NOT NULL,
    "images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "IncidentStatus" NOT NULL DEFAULT 'Reported',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Incident_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "turfId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminAuditLog" (
    "id" TEXT NOT NULL,
    "adminId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "targetType" "AuditTargetType" NOT NULL,
    "details" JSONB NOT NULL DEFAULT '{}',
    "ipAddress" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminAuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expiryDate" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "User_status_idx" ON "User"("status");

-- CreateIndex
CREATE INDEX "Turf_ownerId_idx" ON "Turf"("ownerId");

-- CreateIndex
CREATE INDEX "Turf_status_idx" ON "Turf"("status");

-- CreateIndex
CREATE INDEX "Turf_city_idx" ON "Turf"("city");

-- CreateIndex
CREATE INDEX "Slot_turfId_dayOfWeek_idx" ON "Slot"("turfId", "dayOfWeek");

-- CreateIndex
CREATE UNIQUE INDEX "Slot_turfId_groundName_sport_dayOfWeek_startTime_key" ON "Slot"("turfId", "groundName", "sport", "dayOfWeek", "startTime");

-- CreateIndex
CREATE INDEX "Booking_turfId_bookingDate_idx" ON "Booking"("turfId", "bookingDate");

-- CreateIndex
CREATE INDEX "Booking_userId_idx" ON "Booking"("userId");

-- CreateIndex
CREATE INDEX "Booking_slotId_idx" ON "Booking"("slotId");

-- CreateIndex
CREATE INDEX "Tournament_turfId_idx" ON "Tournament"("turfId");

-- CreateIndex
CREATE INDEX "Tournament_ownerId_idx" ON "Tournament"("ownerId");

-- CreateIndex
CREATE INDEX "Tournament_status_idx" ON "Tournament"("status");

-- CreateIndex
CREATE INDEX "TournamentTeam_tournamentId_idx" ON "TournamentTeam"("tournamentId");

-- CreateIndex
CREATE INDEX "TournamentTeam_captainId_idx" ON "TournamentTeam"("captainId");

-- CreateIndex
CREATE INDEX "TournamentMatch_tournamentId_idx" ON "TournamentMatch"("tournamentId");

-- CreateIndex
CREATE INDEX "TournamentMatch_staffId_idx" ON "TournamentMatch"("staffId");

-- CreateIndex
CREATE INDEX "Payout_ownerId_idx" ON "Payout"("ownerId");

-- CreateIndex
CREATE INDEX "Payout_status_idx" ON "Payout"("status");

-- CreateIndex
CREATE INDEX "Announcement_turfId_idx" ON "Announcement"("turfId");

-- CreateIndex
CREATE INDEX "Attendance_userId_turfId_idx" ON "Attendance"("userId", "turfId");

-- CreateIndex
CREATE INDEX "Maintenance_turfId_idx" ON "Maintenance"("turfId");

-- CreateIndex
CREATE INDEX "Incident_turfId_idx" ON "Incident"("turfId");

-- CreateIndex
CREATE UNIQUE INDEX "Review_bookingId_key" ON "Review"("bookingId");

-- CreateIndex
CREATE INDEX "Review_turfId_idx" ON "Review"("turfId");

-- CreateIndex
CREATE INDEX "AdminAuditLog_adminId_createdAt_idx" ON "AdminAuditLog"("adminId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_token_key" ON "RefreshToken"("token");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_assignedTurfId_fkey" FOREIGN KEY ("assignedTurfId") REFERENCES "Turf"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Turf" ADD CONSTRAINT "Turf_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Slot" ADD CONSTRAINT "Slot_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_slotId_fkey" FOREIGN KEY ("slotId") REFERENCES "Slot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Tournament" ADD CONSTRAINT "Tournament_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Tournament" ADD CONSTRAINT "Tournament_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentTeam" ADD CONSTRAINT "TournamentTeam_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentTeam" ADD CONSTRAINT "TournamentTeam_captainId_fkey" FOREIGN KEY ("captainId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_team1Id_fkey" FOREIGN KEY ("team1Id") REFERENCES "TournamentTeam"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_team2Id_fkey" FOREIGN KEY ("team2Id") REFERENCES "TournamentTeam"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_winnerId_fkey" FOREIGN KEY ("winnerId") REFERENCES "TournamentTeam"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_staffId_fkey" FOREIGN KEY ("staffId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payout" ADD CONSTRAINT "Payout_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Announcement" ADD CONSTRAINT "Announcement_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Maintenance" ADD CONSTRAINT "Maintenance_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Maintenance" ADD CONSTRAINT "Maintenance_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Incident" ADD CONSTRAINT "Incident_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Incident" ADD CONSTRAINT "Incident_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_turfId_fkey" FOREIGN KEY ("turfId") REFERENCES "Turf"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdminAuditLog" ADD CONSTRAINT "AdminAuditLog_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
