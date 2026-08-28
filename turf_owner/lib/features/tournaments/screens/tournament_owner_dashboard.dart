import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import 'manage_teams_screen.dart';
import 'fixture_management_screen.dart';
import 'edit_tournament_screen.dart';

class TournamentOwnerDashboard extends StatelessWidget {
  final Tournament tournament;

  const TournamentOwnerDashboard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditTournamentScreen(tournament: tournament)),
              );
              if (updated == true) {
                // Refresh data if needed or the provider will handle it
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(context),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildSectionHeader('MANAGEMENT'),
            const SizedBox(height: 16),
            _buildManagementCards(context),
            const SizedBox(height: 32),
            _buildSectionHeader('QUICK UPDATES'),
            const SizedBox(height: 16),
            _buildQuickUpdateActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOURNAMENT STATUS',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1),
                ),
                Text(
                  tournament.status.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textMain),
                ),
              ],
            ),
          ),
          if (tournament.status == 'pending_approval')
            const Tooltip(
              message: 'Waiting for Admin approval',
              child: Icon(Icons.hourglass_empty_rounded, color: Colors.orangeAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('REVENUE', 'Rs. ${tournament.registrationFee * tournament.registeredTeamsCount}', Icons.payments_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('TEAMS', '${tournament.registeredTeamsCount} / ${tournament.maxTeams}', Icons.groups_outlined)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 2),
    );
  }

  Widget _buildManagementCards(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          'TEAMS & REGISTRATIONS',
          'Approve or reject team requests',
          Icons.people_outline_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageTeamsScreen(tournamentId: tournament.id))),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          'FIXTURES & BRACKETS',
          'Generate and view match schedules',
          Icons.account_tree_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => FixtureManagementScreen(tournament: tournament))),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
        subtitle: Text(sub, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildQuickUpdateActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(context, 'ANNOUNCEMENT', Icons.campaign_outlined, () {
            // TODO: Navigate to create announcement
          }),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionBtn(context, 'RULES', Icons.gavel_outlined, () {
            // TODO: Edit rules
          }),
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
