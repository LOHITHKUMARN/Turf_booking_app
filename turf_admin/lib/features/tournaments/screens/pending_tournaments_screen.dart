import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';

class PendingTournamentsScreen extends StatefulWidget {
  const PendingTournamentsScreen({super.key});

  @override
  _PendingTournamentsScreenState createState() => _PendingTournamentsScreenState();
}

class _PendingTournamentsScreenState extends State<PendingTournamentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchPendingTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOURNAMENT REQUESTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart_rounded),
            onPressed: () => Navigator.pushNamed(context, '/tournament-monitor'),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pendingTournaments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.pendingTournaments.length,
            itemBuilder: (context, index) {
              final tournament = provider.pendingTournaments[index];
              return _buildPendingCard(context, tournament);
            },
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
          Icon(Icons.checklist_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'NO PENDING REQUESTS',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    tournament.sportsType.toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue[800]),
                  ),
                ),
                Text(
                  'Rs. ${tournament.registrationFee}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.green[800]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tournament.name.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Owner: ${tournament.ownerId}', // Simplified for now
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, tournament.id, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, tournament.id, 'open'),
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

  void _updateStatus(BuildContext context, String id, String status) async {
    final success = await Provider.of<TournamentProvider>(context, listen: false).approveTournament(id, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tournament $status successfully!'), backgroundColor: status == 'open' ? Colors.green : Colors.red),
      );
    }
  }
}
