import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';

class FixtureManagementScreen extends StatefulWidget {
  final Tournament tournament;

  const FixtureManagementScreen({super.key, required this.tournament});

  @override
  _FixtureManagementScreenState createState() => _FixtureManagementScreenState();
}

class _FixtureManagementScreenState extends State<FixtureManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TournamentProvider>(context, listen: false).fetchTournamentMatches(widget.tournament.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIXTURES'),
        actions: [
          if (provider.matches.isNotEmpty)
            IconButton(
              onPressed: () => _generateFixtures(context),
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerate All',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.matches.isEmpty
              ? _buildEmptyState(context)
              : _buildFixtureList(provider),
      floatingActionButton: provider.matches.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMatchDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('MANUAL MATCH'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 100, color: AppTheme.primaryColor.withOpacity(0.1)),
          const SizedBox(height: 32),
          Text(
            'GENERATION PENDING',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Generate single-elimination brackets once you have enough approved teams, or add matches manually.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => _generateFixtures(context),
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            label: const Text('GENERATE FIXTURES'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(250, 60)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showAddMatchDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('ADD MATCH MANUALLY'),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureList(TournamentProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.matches.length,
      itemBuilder: (context, index) {
        final match = provider.matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROUND ${match.round}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(match.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(match.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1?['name'] ?? 'TBD',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[400]),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2?['name'] ?? 'TBD',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          match.startTime != null
                              ? '${match.startTime!.day}/${match.startTime!.month} at ${match.startTime!.hour}:${match.startTime!.minute.toString().padLeft(2, '0')}'
                              : 'TBD',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          match.groundName.isNotEmpty ? match.groundName : 'TBD',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showScheduleDialog(context, match),
                      icon: const Icon(Icons.calendar_month, color: Colors.blue),
                      tooltip: 'Schedule',
                    ),
                    IconButton(
                      onPressed: () => _deleteMatch(context, match),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'live':
        return Colors.red;
      case 'completed':
      case 'verified':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _generateFixtures(BuildContext context) async {
    final success = await Provider.of<TournamentProvider>(context, listen: false).generateFixtures(widget.tournament.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fixtures generated successfully!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 approved teams required'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddMatchDialog(BuildContext context) async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.fetchTournamentTeams(widget.tournament.id);
    
    if (!mounted) return;

    String? selectedTeam1;
    String? selectedTeam2;
    int round = 1;
    int matchIndex = provider.matches.length;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('ADD MANUAL MATCH', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Team 1'),
                items: provider.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (val) => setState(() => selectedTeam1 = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Team 2'),
                items: provider.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (val) => setState(() => selectedTeam2 = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Round'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                onChanged: (val) => round = int.tryParse(val) ?? 1,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: selectedTeam1 == null
                  ? null
                  : () async {
                      final success = await provider.createMatch(widget.tournament.id, {
                        'tournamentId': widget.tournament.id,
                        'team1Id': selectedTeam1,
                        'team2Id': selectedTeam2,
                        'round': round,
                        'matchIndex': matchIndex,
                      });
                      if (success && context.mounted) Navigator.pop(context);
                    },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, TournamentMatch match) async {
    DateTime selectedDate = match.startTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    final TextEditingController groundController = TextEditingController(text: match.groundName);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('ALLOT TIMING', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: selectedTime);
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: groundController,
                decoration: const InputDecoration(labelText: 'Ground/Pitch Name', hintText: 'Example: Ground A'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final start = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final success = await Provider.of<TournamentProvider>(context, listen: false).updateMatch(
                  widget.tournament.id,
                  match.id,
                  {'startTime': start.toIso8601String(), 'groundName': groundController.text},
                );
                if (success && context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMatch(BuildContext context, TournamentMatch match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE MATCH?'),
        content: const Text('Are you sure you want to remove this match from fixtures?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Provider.of<TournamentProvider>(context, listen: false).deleteMatch(widget.tournament.id, match.id);
    }
  }
}
