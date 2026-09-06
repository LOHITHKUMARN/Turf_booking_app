import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../models/tournament_model.dart';

class TeamRegistrationScreen extends StatefulWidget {
  final Tournament tournament;

  const TeamRegistrationScreen({super.key, required this.tournament});

  @override
  State<TeamRegistrationScreen> createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
    // Pre-fill member slots based on team size (excluding captain)
    for (int i = 0; i < widget.tournament.teamSize - 1; i++) {
      _memberControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tournamentProvider = Provider.of<TournamentProvider>(context);
    final captainName = auth.profile?['name'] ?? auth.user?['name'] ?? 'You (Captain)';
    final isTeamNameValid = _nameController.text.trim().isNotEmpty;
    final isEnabled = isTeamNameValid && !tournamentProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'TEAM REGISTRATION',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.emoji_events_rounded, color: Colors.green[800], size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tournament.name,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                widget.tournament.sportsType.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(' • ', style: TextStyle(color: Colors.grey[400])),
                              Text(
                                '${widget.tournament.teamSize} Players Per Team',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Captain Information Note Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.green[800], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Captain Notice',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You are the team captain. You will represent the team and receive tournament schedules and updates.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xCC1B5E20),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: Team Details
              Text(
                'TEAM DETAILS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.green[800],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'e.g. Red Warriors, Striker XI',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.groups_rounded, color: Colors.green[800], size: 22),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Team name is required' : null,
              ),

              const SizedBox(height: 28),

              // Divider between sections
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 24),

              // Section 2: Team Members
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEAM MEMBERS (OPTIONAL)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.green[800],
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${widget.tournament.teamSize} Players',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Member 1 (Captain) Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.green[800],
                      child: Text(
                        '1',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Member 1',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.green[900], fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.amber[800],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                    const SizedBox(width: 2),
                                    Text(
                                      'CAPTAIN',
                                      style: GoogleFonts.outfit(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            captainName,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded, size: 16, color: Colors.green[700]),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Remaining Member Fields (Members 2, 3, 4...)
              ..._memberControllers.asMap().entries.map((entry) {
                final memberNum = entry.key + 2;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: entry.value,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Member $memberNum Name',
                      hintText: 'Enter player name (Optional)',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                      labelStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green[50],
                          child: Text(
                            '$memberNum',
                            style: GoogleFonts.outfit(
                              color: Colors.green[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      suffixText: 'Optional',
                      suffixStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: isEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled ? Colors.green[800] : Colors.grey[300],
                  foregroundColor: isEnabled ? Colors.white : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
                  elevation: isEnabled ? 2 : 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: tournamentProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: isEnabled ? Colors.white : Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SUBMIT REGISTRATION',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final members = _memberControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    
    final success = await provider.registerTeam(
      widget.tournament.id,
      _nameController.text.trim(),
      members,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Back to details
      Navigator.pop(context); // Back to discovery
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register. You might already be enrolled in a team.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
