import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/tournament_model.dart';
import 'tournament_detail_customer_screen.dart';

class TournamentDiscoveryScreen extends StatefulWidget {
  const TournamentDiscoveryScreen({super.key});

  @override
  _TournamentDiscoveryScreenState createState() => _TournamentDiscoveryScreenState();
}

class _TournamentDiscoveryScreenState extends State<TournamentDiscoveryScreen> {
  String? _selectedSport = 'All';
  String get _activeSport => _selectedSport ?? 'All';

  final List<Map<String, dynamic>> _sports = const [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded},
    {'name': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Tennis', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_outlined},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchPublicTournaments();
    });
  }

  void _onSportFilterChanged(String sport) {
    setState(() => _selectedSport = sport);
    Provider.of<TournamentProvider>(context, listen: false).fetchPublicTournaments(
      sport: sport == 'All' ? null : sport,
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Tournaments',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Explore & register your team',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSportsBar(),
          Expanded(
            child: Consumer<TournamentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF15803D), strokeWidth: 2.5),
                  );
                }

                if (provider.tournaments.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: Colors.green[800],
                  onRefresh: () => provider.fetchPublicTournaments(
                    sport: _activeSport == 'All' ? null : _activeSport,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: provider.tournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = provider.tournaments[index];
                      return _buildTournamentCard(context, tournament);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _sports.map((item) {
            final name = item['name'] as String;
            final icon = item['icon'] as IconData;
            final isSelected = _activeSport == name;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onSportFilterChanged(name),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[800] : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green[800]! : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 54, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 16),
            Text(
              _activeSport == 'All' ? 'No tournaments available' : 'No $_activeSport tournaments found',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your sport filter or check back later for upcoming championships.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            if (_activeSport != 'All') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _onSportFilterChanged('All'),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Show All Sports'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[800],
                  side: BorderSide(color: Colors.green[800]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    final maxTeams = tournament.maxTeams > 0 ? tournament.maxTeams : 1;
    final fillRatio = (tournament.registeredTeamsCount / maxTeams).clamp(0.0, 1.0);
    final isFull = tournament.registeredTeamsCount >= tournament.maxTeams && tournament.maxTeams > 0;
    final isFillingFast = !isFull && fillRatio >= 0.7;

    // Image resolution: bannerImage -> turf images -> fallback sport gradient
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

    final startDateFormatted = DateFormat('d MMM').format(tournament.startDate);
    final venueName = tournament.turf is Map ? (tournament.turf['name'] ?? 'Venue TBA') : 'Venue TBA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TournamentDetailCustomerScreen(tournament: tournament),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Visual Banner Section with status badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: hasValidImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackBanner(tournament.sportsType),
                            )
                          : _buildFallbackBanner(tournament.sportsType),
                    ),
                  ),

                  // Dark subtle gradient overlay on bottom of banner for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left Status Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildStatusBadge(
                      isRegistered: tournament.isRegistered,
                      isFull: isFull,
                      isFillingFast: isFillingFast,
                    ),
                  ),

                  // Top-Right Date / Prize Chip
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            startDateFormatted,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Tournament Details Section
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row A: Category Tag + Price Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                          ),
                          child: Text(
                            tournament.sportsType.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),

                        // Price Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: tournament.registrationFee == 0
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tournament.registrationFee == 0
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tournament.registrationFee == 0
                                ? 'FREE'
                                : '₹${tournament.registrationFee.toInt() == tournament.registrationFee ? tournament.registrationFee.toInt() : tournament.registrationFee}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: tournament.registrationFee == 0
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Tournament Title
                    Text(
                      tournament.name,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venueName,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Row C: Teams Fill Indicator & Prize Pool
                    Row(
                      children: [
                        // Left: Teams Fill Meter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 13,
                                    color: isFull ? const Color(0xFFE11D48) : const Color(0xFF047857),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${tournament.registeredTeamsCount}/${tournament.maxTeams} Teams',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isFull ? const Color(0xFFE11D48) : const Color(0xFF334155),
                                    ),
                                  ),
                                  if (isFillingFast) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '• Filling fast',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fillRatio,
                                  minHeight: 4.5,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isFull
                                        ? const Color(0xFFE11D48)
                                        : isFillingFast
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Right: Prize Pool or Team Size
                        if (tournament.prizePool.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded, size: 12, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Text(
                                  tournament.prizePool,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            '${tournament.teamSize} vs ${tournament.teamSize}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(String sport) {
    final gradientColors = _getSportGradient(sport);
    final icon = _getSportIcon(sport);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: Icon(
              icon,
              size: 90,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Positioned(
            left: -10,
            top: -10,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 55,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: 40,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isRegistered,
    required bool isFull,
    required bool isFillingFast,
  }) {
    if (isRegistered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF059669),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'REGISTERED',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(
          'SLOTS FULL',
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
    }

    if (isFillingFast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              'FILLING FAST',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            'OPEN',
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
