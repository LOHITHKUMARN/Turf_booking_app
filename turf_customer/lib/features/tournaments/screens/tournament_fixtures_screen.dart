import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import 'package:intl/intl.dart';

class TournamentFixturesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentFixturesScreen({
    super.key, 
    required this.tournamentId, 
    required this.tournamentName
  });

  @override
  _TournamentFixturesScreenState createState() => _TournamentFixturesScreenState();
}

class _TournamentFixturesScreenState extends State<TournamentFixturesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchTournamentMatches(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.matches.isEmpty
              ? _buildEmptyState()
              : _buildFixtureList(provider.matches),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'NO FIXTURES YET',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'The organizer hasn\'t scheduled any matches yet.',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureList(List<TournamentMatch> matches) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    final bool isCompleted = match.status == 'completed' || match.status == 'verified';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROUND ${match.round}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                _buildStatusBadge(match.status),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTeamInfo(match.team1?['name'] ?? 'TBD', match.score1, match.winnerId == match.team1Id && match.winnerId != null)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[300]),
                  ),
                ),
                Expanded(child: _buildTeamInfo(match.team2?['name'] ?? 'TBD', match.score2, match.winnerId == match.team2Id && match.winnerId != null, isLeft: false)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  match.startTime != null 
                    ? DateFormat('EEE, MMM d • hh:mm a').format(match.startTime!)
                    : 'Time TBD',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  match.groundName.isNotEmpty ? match.groundName : 'Venue TBD',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String name, int score, bool isWinner, {bool isLeft = true}) {
    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 16, 
            fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
            color: isWinner ? Colors.green[900] : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (score > 0 || isWinner)
          Text(
            score.toString(),
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isWinner ? Colors.green : Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'live': color = Colors.red; break;
      case 'completed': 
      case 'verified': color = Colors.green; break;
      case 'cancelled': color = Colors.grey; break;
      default: color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
