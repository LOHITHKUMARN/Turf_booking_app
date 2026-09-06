import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/tournament_model.dart';
import 'team_registration_screen.dart';
import 'tournament_fixtures_screen.dart';

class TournamentDetailCustomerScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailCustomerScreen({super.key, required this.tournament});

  String _formatFee(double fee) {
    if (fee <= 0) return 'FREE';
    final isInt = fee.toInt() == fee;
    return '₹${isInt ? fee.toInt() : fee.toStringAsFixed(1)}';
  }

  String _formatPrize(String prize) {
    if (prize.trim().isEmpty) return 'Trophy & Medals';
    final clean = prize.replaceAll('Rs.', '').replaceAll('Rs', '').replaceAll('₹', '').replaceAll(',', '').trim();
    final numVal = num.tryParse(clean);
    if (numVal != null) {
      return '₹${NumberFormat('#,##,###').format(numVal)}';
    }
    return prize.startsWith('₹') ? prize : '₹$prize';
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'football':
      case 'soccer':
        return Icons.sports_soccer_rounded;
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'badminton':
        return Icons.sports_tennis_outlined;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  List<Color> _getSportGradient(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return [const Color(0xFF0F766E), const Color(0xFF14B8A6)];
      case 'football':
      case 'soccer':
        return [const Color(0xFF166534), const Color(0xFF22C55E)];
      case 'tennis':
        return [const Color(0xFF854D0E), const Color(0xFFEAB308)];
      case 'badminton':
        return [const Color(0xFF1E40AF), const Color(0xFF3B82F6)];
      default:
        return [const Color(0xFF1B5E20), const Color(0xFF388E3C)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = tournament.maxTeams > 0 && tournament.registeredTeamsCount >= tournament.maxTeams;
    final isDeadlinePassed = DateTime.now().isAfter(tournament.registrationDeadline);
    final canRegister = !tournament.isRegistered && !isFull && !isDeadlinePassed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Tournament Details',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sleek Hero Banner (Height 190px)
            _buildHeroSection(),

            // 2. Main Content Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 18),
                  _buildPrizeSection(),
                  const SizedBox(height: 18),
                  _buildFixturesAction(context),

                  // Rules Section (Only shown if real rules exist)
                  if (tournament.rules.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _buildSectionTitle('TOURNAMENT RULES'),
                    const SizedBox(height: 12),
                    _buildRulesCard(),
                  ],

                  // Space for sticky bottom action bar
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context, canRegister, isFull, isDeadlinePassed),
    );
  }

  Widget _buildHeroSection() {
    String imageUrl = '';
    if (tournament.bannerImage.isNotEmpty) {
      imageUrl = ApiConstants.getFullUrl(tournament.bannerImage);
    } else if (tournament.turf is Map &&
        tournament.turf['images'] != null &&
        (tournament.turf['images'] as List).isNotEmpty) {
      final firstImg = tournament.turf['images'][0]?.toString() ?? '';
      imageUrl = ApiConstants.getFullUrl(firstImg);
    }

    bool hasValidImage = false;
    if (imageUrl.isNotEmpty) {
      final uri = Uri.tryParse(imageUrl);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
        hasValidImage = true;
      }
    }

    return Stack(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: hasValidImage
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackHero(),
                )
              : _buildFallbackHero(),
        ),

        // Gradient overlay for contrast with AppBar and bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),

        // Status Badge Overlay at bottom-left of hero
        Positioned(
          bottom: 14,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tournament.isRegistered
                  ? const Color(0xFF059669)
                  : Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tournament.isRegistered ? const Color(0xFFA7F3D0) : Colors.white24,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tournament.isRegistered ? Icons.check_circle_rounded : Icons.sports_score_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  tournament.isRegistered ? 'ENROLLED' : tournament.status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackHero() {
    final gradient = _getSportGradient(tournament.sportsType);
    final icon = _getSportIcon(tournament.sportsType);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 140,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: 56,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final venueName = tournament.turf is Map ? (tournament.turf['name'] ?? 'Venue TBA') : 'Venue TBA';
    final venueCity = tournament.turf is Map && tournament.turf['city'] != null
        ? ' • ${tournament.turf['city']}'
        : '';
    final startDateStr = DateFormat('d MMM yyyy').format(tournament.startDate);
    final endDateStr = DateFormat('d MMM yyyy').format(tournament.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pill & Format Badge Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getSportIcon(tournament.sportsType), size: 12, color: const Color(0xFF047857)),
                  const SizedBox(width: 4),
                  Text(
                    tournament.sportsType.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '${tournament.teamSize} vs ${tournament.teamSize} Teams',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Full Tournament Title
        Text(
          tournament.name,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.25,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),

        // Venue Location Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF059669)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$venueName$venueCity',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tournament Schedule Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MATCH DATES',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      startDateStr == endDateStr ? startDateStr : '$startDateStr - $endDateStr',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Description
        if (tournament.description.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            tournament.description,
            style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569), height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildPrizeSection() {
    final formattedPrize = _formatPrize(tournament.prizePool);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0DB45309),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIZE POOL',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB45309),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedPrize,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF92400E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Winner Trophy, Medals & Recognition',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: tournament.rules.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rule,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFixturesAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TournamentFixturesScreen(
                tournamentId: tournament.id,
                tournamentName: tournament.name,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_tree_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tournament Fixtures & Schedule',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View match brackets, rounds & live results',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool canRegister,
    bool isFull,
    bool isDeadlinePassed,
  ) {
    String buttonText = 'REGISTER NOW';
    if (tournament.isRegistered) {
      buttonText = 'ENROLLED';
    } else if (isFull) {
      buttonText = 'SLOTS FULL';
    } else if (isDeadlinePassed) {
      buttonText = 'REGISTRATION CLOSED';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Left: Clean Entry Fee & Slots count
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ENTRY FEE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFull ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${tournament.registeredTeamsCount}/${tournament.maxTeams} Teams',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isFull ? const Color(0xFFE11D48) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFee(tournament.registrationFee),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            // Right: Primary Registration Button
            ElevatedButton(
              onPressed: canRegister
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamRegistrationScreen(tournament: tournament),
                        ),
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: canRegister ? 2 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: canRegister ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  if (canRegister) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
