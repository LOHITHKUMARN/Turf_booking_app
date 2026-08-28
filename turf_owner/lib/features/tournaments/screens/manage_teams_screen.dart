import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';

class ManageTeamsScreen extends StatefulWidget {
  final String tournamentId;

  const ManageTeamsScreen({super.key, required this.tournamentId});

  @override
  _ManageTeamsScreenState createState() => _ManageTeamsScreenState();
}

class _ManageTeamsScreenState extends State<ManageTeamsScreen> {
  List<TournamentTeam>? _teams;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.fetchTournamentTeams(widget.tournamentId);
    if (mounted) {
      setState(() {
        _teams = provider.teams;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MANAGE TEAMS')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams == null || _teams!.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _teams!.length,
                  itemBuilder: (context, index) {
                    final team = _teams![index];
                    return _buildTeamCard(team);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'NO TEAMS REGISTERED',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TournamentTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  team.name.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                _buildStatusChip(team.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Captain: ${team.captain?['name'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (team.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(team.id, 'rejected'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(team.id, 'approved'),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  void _updateStatus(String teamId, String status) async {
    final success = await Provider.of<TournamentProvider>(context, listen: false).updateTeamStatus(teamId, status);
    if (success) {
      _loadTeams();
    }
  }
}
