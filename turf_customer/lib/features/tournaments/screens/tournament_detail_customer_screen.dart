import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import 'team_registration_screen.dart';
import 'tournament_fixtures_screen.dart';

class TournamentDetailCustomerScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailCustomerScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('DETAILS'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 32),
                  _buildPrizeSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('RULES'),
                  const SizedBox(height: 12),
                  ...tournament.rules.map((rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(rule, style: GoogleFonts.poppins(fontSize: 14))),
                          ],
                        ),
                      )),
                  if (tournament.rules.isEmpty)
                    Text('General tournament rules apply.', style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                  _buildFixturesButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.green,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green, Color(0xFF1B5E20)],
        ),
      ),
      child: Center(
        child: Icon(Icons.emoji_events_rounded, size: 120, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tournament.name.toUpperCase(),
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              tournament.turf?['name'] ?? 'Unknown Venue',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          tournament.description,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPrizeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber[100], shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIZE POOL', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                Text(
                  tournament.prizePool.isNotEmpty ? tournament.prizePool : 'Trophy & Medals',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber[900]),
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
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green[900], letterSpacing: 1),
    );
  }

  Widget _buildFixturesButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TournamentFixturesScreen(
              tournamentId: tournament.id,
              tournamentName: tournament.name,
            ),
          ),
        ),
        icon: const Icon(Icons.account_tree_outlined),
        label: const Text('VIEW TOURNAMENT FIXTURES'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.green[800]!),
          foregroundColor: Colors.green[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('ENTRY FEE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${tournament.registeredTeamsCount}/${tournament.maxTeams} TEAMS',
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rs. ${tournament.registrationFee}',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green[900]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: tournament.isRegistered == true
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TeamRegistrationScreen(tournament: tournament)),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: tournament.isRegistered == true ? Colors.grey : Colors.green[800],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: Text(
              tournament.isRegistered == true ? 'REGISTERED' : 'REGISTER NOW',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
