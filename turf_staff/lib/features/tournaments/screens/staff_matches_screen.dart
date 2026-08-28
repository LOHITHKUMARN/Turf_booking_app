import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/tournament_provider.dart';
import '../../../models/tournament_model.dart';
import 'match_verification_screen.dart';

class StaffMatchesScreen extends StatefulWidget {
  const StaffMatchesScreen({super.key});

  @override
  _StaffMatchesScreenState createState() => _StaffMatchesScreenState();
}

class _StaffMatchesScreenState extends State<StaffMatchesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchStaffMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: const Text('TOURNAMENT MATCHES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => Provider.of<TournamentProvider>(context, listen: false).fetchStaffMatches(),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.staffMatches.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: provider.staffMatches.length,
            itemBuilder: (context, index) {
              final match = provider.staffMatches[index];
              return _buildMatchCard(context, match);
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
          const Icon(Icons.sports_soccer, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            "No matches today",
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, TournamentMatch match) {
    final startTime = match.startTime != null ? DateFormat('HH:mm').format(match.startTime!) : '04:35';
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchVerificationScreen(match: match)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 TOP ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startTime,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                _buildStatusChip(match.status),
              ],
            ),

            const SizedBox(height: 16),

            // ⚽ TEAM VS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _team(match.team1?.name.toUpperCase() ?? "TBD", Colors.green),
                Text("VS", style: GoogleFonts.outfit(color: Colors.grey)),
                _team(match.team2?.name.toUpperCase() ?? "TBD", Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 12),

            // 📍 LOCATION + CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      match.groundName.isEmpty ? "Court 1" : match.groundName,
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "VERIFY",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _team(String name, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(Icons.sports_soccer, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'completed') color = Colors.blue;
    if (status == 'ongoing') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
