import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';

class TeamRegistrationScreen extends StatefulWidget {
  final Tournament tournament;

  const TeamRegistrationScreen({super.key, required this.tournament});

  @override
  _TeamRegistrationScreenState createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill member slots based on team size (excluding captain)
    for (int i = 0; i < widget.tournament.teamSize - 1; i++) {
      _memberControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEAM REGISTRATION')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TEAM DETAILS',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green[800], letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Team Name', hintText: 'e.g. Red Warriors'),
                validator: (val) => val!.isEmpty ? 'Team name is required' : null,
              ),
              const SizedBox(height: 32),
              Text(
                'TEAM MEMBERS (OPTIONAL)',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green[800], letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              ..._memberControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: 'Member ${entry.key + 2} Name'),
                  ),
                );
              }),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('SUBMIT REGISTRATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Note: You are the team captain.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final members = _memberControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();
    
    final success = await provider.registerTeam(
      widget.tournament.id,
      _nameController.text,
      members,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Waiting for owner approval.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Back to details
      Navigator.pop(context); // Back to discovery
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register. You might be already in a team.'), backgroundColor: Colors.red),
      );
    }
  }
}
