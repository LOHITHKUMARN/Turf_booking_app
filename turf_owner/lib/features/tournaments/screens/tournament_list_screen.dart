import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import 'tournament_owner_dashboard.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  _TournamentListScreenState createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<TournamentProvider>(context, listen: false);
      provider.fetchMyTournaments();
      provider.initSocketListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY TOURNAMENTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => Provider.of<TournamentProvider>(context, listen: false).fetchMyTournaments(),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myTournaments.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.myTournaments.length,
            itemBuilder: (context, index) {
              final tournament = provider.myTournaments[index];
              return _buildTournamentCard(context, tournament);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-tournament'),
        label: const Text('NEW TOURNAMENT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'NO TOURNAMENTS YET',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Host your first tournament to engage with players!',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/create-tournament'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            child: const Text('CREATE NOW'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentOwnerDashboard(tournament: tournament),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tournament.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tournament.status.toUpperCase().replaceAll('_', ' '),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(tournament.status),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    'Rs. ${tournament.registrationFee}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tournament.name.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textMain),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.sports_soccer_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    tournament.sportsType,
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.groups_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${tournament.teamSize}v${tournament.teamSize}',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${tournament.startDate.day}/${tournament.startDate.month} - ${tournament.endDate.day}/${tournament.endDate.month}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tournament.registeredTeamsCount}/${tournament.maxTeams} TEAMS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'pending_approval':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
