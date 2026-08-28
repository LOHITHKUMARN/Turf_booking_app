class Tournament {
  final String id;
  final String ownerId;
  final String turfId;
  final String name;
  final String description;
  final String sportsType;
  final int teamSize;
  final int maxTeams;
  final double registrationFee;
  final String prizePool;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final List<String> rules;
  final String status;
  final String bannerImage;
  final String adminNotes;
  final int registeredTeamsCount;
  final dynamic turf; // Populated turf data

  Tournament({
    required this.id,
    required this.ownerId,
    required this.turfId,
    required this.name,
    required this.description,
    required this.sportsType,
    required this.teamSize,
    required this.maxTeams,
    required this.registrationFee,
    required this.prizePool,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.rules,
    required this.status,
    required this.bannerImage,
    required this.adminNotes,
    required this.registeredTeamsCount,
    this.turf,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['_id'] ?? '',
      ownerId: json['ownerId'] is Map ? json['ownerId']['_id'] : (json['ownerId'] ?? ''),
      turfId: json['turfId'] is Map ? json['turfId']['_id'] : (json['turfId'] ?? ''),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sportsType: json['sportsType'] ?? '',
      teamSize: json['teamSize'] ?? 0,
      maxTeams: json['maxTeams'] ?? 0,
      registrationFee: (json['registrationFee'] ?? 0).toDouble(),
      prizePool: json['prizePool'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      registrationDeadline: DateTime.parse(json['registrationDeadline']),
      rules: List<String>.from(json['rules'] ?? []),
      status: json['status'] ?? 'pending_approval',
      bannerImage: json['bannerImage'] ?? '',
      adminNotes: json['adminNotes'] ?? '',
      registeredTeamsCount: json['registeredTeamsCount'] ?? 0,
      turf: json['turfId'],
    );
  }
}

class TournamentTeam {
  final String id;
  final String tournamentId;
  final String captainId;
  final String name;
  final List<String> members;
  final String status;
  final String paymentStatus;
  final String transactionId;
  final dynamic captain; // Populated captain data

  TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.captainId,
    required this.name,
    required this.members,
    required this.status,
    required this.paymentStatus,
    required this.transactionId,
    this.captain,
  });

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['_id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      captainId: json['captainId'] is Map ? json['captainId']['_id'] : (json['captainId'] ?? ''),
      name: json['name'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      transactionId: json['transactionId'] ?? '',
      captain: json['captainId'],
    );
  }
}

class TournamentMatch {
  final String id;
  final String tournamentId;
  final String? team1Id;
  final String? team2Id;
  final String? winnerId;
  final int score1;
  final int score2;
  final int round;
  final int matchIndex;
  final DateTime? startTime;
  final String groundName;
  final String status;
  final bool isVerified;
  final dynamic team1;
  final dynamic team2;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.team1Id,
    this.team2Id,
    this.winnerId,
    required this.score1,
    required this.score2,
    required this.round,
    required this.matchIndex,
    this.startTime,
    required this.groundName,
    required this.status,
    required this.isVerified,
    this.team1,
    this.team2,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['_id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      team1Id: json['team1Id'] is Map ? json['team1Id']['_id'] : (json['team1Id']),
      team2Id: json['team2Id'] is Map ? json['team2Id']['_id'] : (json['team2Id']),
      winnerId: json['winnerId'] ?? '',
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      round: json['round'] ?? 1,
      matchIndex: json['matchIndex'] ?? 0,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      groundName: json['groundName'] ?? '',
      status: json['status'] ?? 'scheduled',
      isVerified: json['isVerified'] ?? false,
      team1: json['team1Id'],
      team2: json['team2Id'],
    );
  }
}
