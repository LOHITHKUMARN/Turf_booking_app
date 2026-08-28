import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import 'tournament_detail_customer_screen.dart';

class TournamentDiscoveryScreen extends StatefulWidget {
  const TournamentDiscoveryScreen({super.key});

  @override
  _TournamentDiscoveryScreenState createState() => _TournamentDiscoveryScreenState();
}

class _TournamentDiscoveryScreenState extends State<TournamentDiscoveryScreen> {
  String? _selectedSport;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchPublicTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TOURNAMENTS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.green[800])),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<TournamentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.tournaments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = provider.tournaments[index];
                    return _buildTournamentCard(context, tournament);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final sports = ['Football', 'Cricket', 'Tennis', 'Badminton'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sports.length,
        itemBuilder: (context, index) {
          final sport = sports[index];
          final isSelected = _selectedSport == sport;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(sport),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSport = selected ? sport : null);
                Provider.of<TournamentProvider>(context, listen: false)
                    .fetchPublicTournaments(sport: _selectedSport);
              },
              selectedColor: Colors.green[800],
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'NO TOURNAMENTS FOUND',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TournamentDetailCustomerScreen(tournament: tournament))
        ),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 60, color: Colors.green),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tournament.sportsType.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                      Row(
                        children: [
                          if (tournament.isRegistered == true)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                'REGISTERED',
                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[900]),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Rs. ${tournament.registrationFee}',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tournament.name,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        tournament.turf?['name'] ?? 'Unknown Venue',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Starts ${tournament.startDate.day}/${tournament.startDate.month}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.people_alt_rounded, size: 14, color: Colors.green[800]),
                          const SizedBox(width: 4),
                          Text(
                            '${tournament.registeredTeamsCount}/${tournament.maxTeams} TEAMS',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
