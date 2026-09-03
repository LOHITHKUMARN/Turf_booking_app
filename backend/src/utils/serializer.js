/**
 * Serialization and Compatibility Layer
 * 
 * Guarantees 100% backward compatibility for the 4 Flutter mobile applications:
 * - turf_customer
 * - turf_owner
 * - turf_staff
 * - turf_admin
 * 
 * Reconstructs nested MongoDB structures (location, settings), provides both `id` and `_id`,
 * ensures exact enum casing, ISO dates, and populated relationship shapes.
 */

const serializeUser = (user) => {
    if (!user) return null;
    const { id, owner, assignedTurf, turfsOwned, bookings, ...rest } = user;
    return {
        _id: id,
        id,
        ...rest,
        role: user.role ? user.role.toLowerCase() : 'customer',
        status: user.status ? user.status.toLowerCase() : 'active',
        createdAt: user.createdAt ? new Date(user.createdAt).toISOString() : undefined,
        updatedAt: user.updatedAt ? new Date(user.updatedAt).toISOString() : undefined,
    };
};

const serializeTurf = (turf) => {
    if (!turf) return null;
    const {
        id,
        city,
        area,
        minBookingDuration,
        advanceBookingLimit,
        bookingCutoffTime,
        gracePeriod,
        maxMembers,
        upiId,
        taxPercentage,
        avgRating,
        numReviews,
        owner,
        assignedStaff,
        slots,
        bookings,
        tournaments,
        announcements,
        attendanceLogs,
        maintenances,
        incidents,
        reviews,
        ...rest
    } = turf;

    // Build populated ownerId if included
    let ownerIdVal = turf.ownerId;
    if (owner && typeof owner === 'object') {
        ownerIdVal = {
            _id: owner.id,
            id: owner.id,
            name: owner.name,
            email: owner.email,
            phone: owner.phone,
            role: owner.role
        };
    }

    return {
        _id: id,
        id,
        ...rest,
        ownerId: ownerIdVal,
        location: {
            city: city || 'N/A',
            area: area || 'N/A'
        },
        settings: {
            minBookingDuration: minBookingDuration ?? 1,
            advanceBookingLimit: advanceBookingLimit ?? 7,
            bookingCutoffTime: bookingCutoffTime ?? 2,
            gracePeriod: gracePeriod ?? 15,
            maxMembers: maxMembers ?? 10,
            upiId: upiId || '',
            taxPercentage: Number(taxPercentage) || 0,
            avgRating: Number(avgRating) || 0,
            numReviews: numReviews || 0
        },
        turfType: turf.turfType ? turf.turfType.toLowerCase() : 'both',
        status: turf.status ? turf.status.toLowerCase() : 'pending',
        operationalStatus: turf.operationalStatus === 'power_issue' 
            ? 'power-issue' 
            : turf.operationalStatus === 'heavy_rain' 
            ? 'heavy-rain' 
            : (turf.operationalStatus || 'normal').toLowerCase(),
        grounds: turf.grounds || [],
        sports: turf.sports || [],
        amenities: turf.amenities || [],
        images: turf.images || [],
        createdAt: turf.createdAt ? new Date(turf.createdAt).toISOString() : undefined,
        updatedAt: turf.updatedAt ? new Date(turf.updatedAt).toISOString() : undefined,
    };
};

const serializeSlot = (slot, isBooked = false) => {
    if (!slot) return null;
    const { id, turf, bookings, ...rest } = slot;
    return {
        _id: id,
        id,
        ...rest,
        isBooked: typeof slot.isBooked === 'boolean' ? slot.isBooked : isBooked,
        createdAt: slot.createdAt ? new Date(slot.createdAt).toISOString() : undefined,
        updatedAt: slot.updatedAt ? new Date(slot.updatedAt).toISOString() : undefined,
    };
};

const serializeBooking = (booking) => {
    if (!booking) return null;
    const { id, turf, slot, user, review, extraCharges, ...rest } = booking;

    let turfIdVal = booking.turfId;
    if (turf && typeof turf === 'object') {
        turfIdVal = {
            _id: turf.id,
            id: turf.id,
            name: turf.name,
            images: turf.images || [],
            location: {
                city: turf.city || 'N/A',
                area: turf.area || 'N/A'
            }
        };
    }

    let slotIdVal = booking.slotId;
    if (slot && typeof slot === 'object') {
        slotIdVal = {
            _id: slot.id,
            id: slot.id,
            startTime: slot.startTime,
            endTime: slot.endTime,
            sport: slot.sport,
            groundName: slot.groundName || '',
            price: slot.price
        };
    }

    let userIdVal = booking.userId;
    if (user && typeof user === 'object') {
        userIdVal = {
            _id: user.id,
            id: user.id,
            name: user.name,
            phone: user.phone,
            email: user.email
        };
    }

    return {
        _id: id,
        id,
        ...rest,
        userId: userIdVal,
        turfId: turfIdVal,
        slotId: slotIdVal,
        bookingDate: booking.bookingDate ? new Date(booking.bookingDate).toISOString() : undefined,
        bookingStatus: booking.bookingStatus === 'checked_in' 
            ? 'checked-in' 
            : booking.bookingStatus === 'no_show' 
            ? 'no-show' 
            : (booking.bookingStatus || 'confirmed').toLowerCase(),
        paymentStatus: (booking.paymentStatus || 'pending').toLowerCase(),
        paymentMethod: (booking.paymentMethod || 'cash').toLowerCase(),
        extraCharges: Array.isArray(extraCharges) ? extraCharges : [],
        createdAt: booking.createdAt ? new Date(booking.createdAt).toISOString() : undefined,
        updatedAt: booking.updatedAt ? new Date(booking.updatedAt).toISOString() : undefined,
    };
};

const serializeTournament = (tournament) => {
    if (!tournament) return null;
    const { id, owner, turf, teams, matches, ...rest } = tournament;

    let turfIdVal = tournament.turfId;
    if (turf && typeof turf === 'object') {
        turfIdVal = {
            _id: turf.id,
            id: turf.id,
            name: turf.name,
            location: { city: turf.city, area: turf.area }
        };
    }

    let ownerIdVal = tournament.ownerId;
    if (owner && typeof owner === 'object') {
        ownerIdVal = {
            _id: owner.id,
            id: owner.id,
            name: owner.name,
            phone: owner.phone
        };
    }

    return {
        _id: id,
        id,
        ...rest,
        turfId: turfIdVal,
        ownerId: ownerIdVal,
        startDate: tournament.startDate ? new Date(tournament.startDate).toISOString() : undefined,
        endDate: tournament.endDate ? new Date(tournament.endDate).toISOString() : undefined,
        registrationDeadline: tournament.registrationDeadline ? new Date(tournament.registrationDeadline).toISOString() : undefined,
        status: (tournament.status || 'pending_approval').toLowerCase(),
        rules: tournament.rules || [],
        createdAt: tournament.createdAt ? new Date(tournament.createdAt).toISOString() : undefined,
        updatedAt: tournament.updatedAt ? new Date(tournament.updatedAt).toISOString() : undefined,
    };
};

const serializeTeam = (team) => {
    if (!team) return null;
    const { id, captain, tournament, homeMatches, awayMatches, matchesWon, ...rest } = team;

    let captainVal = team.captainId;
    if (captain && typeof captain === 'object') {
        captainVal = {
            _id: captain.id,
            id: captain.id,
            name: captain.name,
            phone: captain.phone,
            email: captain.email
        };
    }

    return {
        _id: id,
        id,
        ...rest,
        captainId: captainVal,
        status: (team.status || 'pending').toLowerCase(),
        paymentStatus: (team.paymentStatus || 'pending').toLowerCase(),
        members: team.members || [],
        createdAt: team.createdAt ? new Date(team.createdAt).toISOString() : undefined,
        updatedAt: team.updatedAt ? new Date(team.updatedAt).toISOString() : undefined,
    };
};

const serializeMatch = (match) => {
    if (!match) return null;
    const { id, tournament, team1, team2, winner, staff, ...rest } = match;

    return {
        _id: id,
        id,
        ...rest,
        team1Id: team1 ? serializeTeam(team1) : match.team1Id,
        team2Id: team2 ? serializeTeam(team2) : match.team2Id,
        winnerId: winner ? serializeTeam(winner) : match.winnerId,
        staffId: staff ? serializeUser(staff) : match.staffId,
        startTime: match.startTime ? new Date(match.startTime).toISOString() : undefined,
        status: (match.status || 'scheduled').toLowerCase(),
        createdAt: match.createdAt ? new Date(match.createdAt).toISOString() : undefined,
        updatedAt: match.updatedAt ? new Date(match.updatedAt).toISOString() : undefined,
    };
};

const serializePayout = (payout) => {
    if (!payout) return null;
    const { id, owner, ...rest } = payout;
    return {
        _id: id,
        id,
        ...rest,
        status: (payout.status || 'pending').toLowerCase(),
        bankDetails: payout.bankDetails || {},
        requestedAt: payout.requestedAt ? new Date(payout.requestedAt).toISOString() : undefined,
        processedAt: payout.processedAt ? new Date(payout.processedAt).toISOString() : undefined,
        createdAt: payout.createdAt ? new Date(payout.createdAt).toISOString() : undefined,
        updatedAt: payout.updatedAt ? new Date(payout.updatedAt).toISOString() : undefined,
    };
};

const serializeAttendance = (attendance) => {
    if (!attendance) return null;
    const { id, user, turf, ...rest } = attendance;
    return {
        _id: id,
        id,
        ...rest,
        clockIn: attendance.clockIn ? new Date(attendance.clockIn).toISOString() : undefined,
        clockOut: attendance.clockOut ? new Date(attendance.clockOut).toISOString() : undefined,
        createdAt: attendance.createdAt ? new Date(attendance.createdAt).toISOString() : undefined,
        updatedAt: attendance.updatedAt ? new Date(attendance.updatedAt).toISOString() : undefined,
    };
};

const serializeIncident = (incident) => {
    if (!incident) return null;
    const { id, turf, reporter, ...rest } = incident;
    return {
        _id: id,
        id,
        ...rest,
        type: incident.type === 'Crowd_Issue' ? 'Crowd Issue' : incident.type,
        status: incident.status === 'Under_Investigation' ? 'Under Investigation' : incident.status,
        images: incident.images || [],
        createdAt: incident.createdAt ? new Date(incident.createdAt).toISOString() : undefined,
        updatedAt: incident.updatedAt ? new Date(incident.updatedAt).toISOString() : undefined,
    };
};

const serializeMaintenance = (maint) => {
    if (!maint) return null;
    const { id, turf, reporter, ...rest } = maint;
    return {
        _id: id,
        id,
        ...rest,
        status: maint.status === 'In_Progress' ? 'In Progress' : maint.status,
        images: maint.images || [],
        createdAt: maint.createdAt ? new Date(maint.createdAt).toISOString() : undefined,
        updatedAt: maint.updatedAt ? new Date(maint.updatedAt).toISOString() : undefined,
    };
};

const serializeReview = (review) => {
    if (!review) return null;
    const { id, user, turf, booking, ...rest } = review;

    let userVal = review.userId;
    if (user && typeof user === 'object') {
        userVal = {
            _id: user.id,
            id: user.id,
            name: user.name,
            profileImage: user.profileImage || ''
        };
    }

    return {
        _id: id,
        id,
        ...rest,
        userId: userVal,
        createdAt: review.createdAt ? new Date(review.createdAt).toISOString() : undefined,
        updatedAt: review.updatedAt ? new Date(review.updatedAt).toISOString() : undefined,
    };
};

const serializeAnnouncement = (announcement) => {
    if (!announcement) return null;
    const { id, turf, ...rest } = announcement;
    return {
        _id: id,
        id,
        ...rest,
        type: announcement.type === 'Shift_Update' ? 'Shift Update' : announcement.type,
        createdAt: announcement.createdAt ? new Date(announcement.createdAt).toISOString() : undefined,
        updatedAt: announcement.updatedAt ? new Date(announcement.updatedAt).toISOString() : undefined,
    };
};

const serializeAuditLog = (log) => {
    if (!log) return null;
    const { id, admin, ...rest } = log;
    return {
        _id: id,
        id,
        ...rest,
        createdAt: log.createdAt ? new Date(log.createdAt).toISOString() : undefined,
        updatedAt: log.updatedAt ? new Date(log.updatedAt).toISOString() : undefined,
    };
};

module.exports = {
    serializeUser,
    serializeTurf,
    serializeSlot,
    serializeBooking,
    serializeTournament,
    serializeTeam,
    serializeMatch,
    serializePayout,
    serializeAttendance,
    serializeIncident,
    serializeMaintenance,
    serializeReview,
    serializeAnnouncement,
    serializeAuditLog
};
