import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';

class TournamentMonitorScreen extends StatefulWidget {
  const TournamentMonitorScreen({super.key});

  @override
  _TournamentMonitorScreenState createState() => _TournamentMonitorScreenState();
}

class _TournamentMonitorScreenState extends State<TournamentMonitorScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchAllTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GLOBAL MONITOR')),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.allTournaments.isEmpty) {
            return const Center(child: Text('No tournaments found globally.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.allTournaments.length,
            itemBuilder: (context, index) {
              final tournament = provider.allTournaments[index];
              return _buildMonitorCard(tournament);
            },
          );
        },
      ),
    );
  }

  Widget _buildMonitorCard(Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: const Icon(Icons.emoji_events_rounded, color: Colors.green),
        ),
        title: Text(tournament.name.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text('${tournament.sportsType} | ${tournament.status.toUpperCase()}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // TODO: Detailed global view
        },
      ),
    );
  }
}
