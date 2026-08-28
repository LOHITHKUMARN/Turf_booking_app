import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../providers/turf_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/turf_model.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  _CreateTournamentScreenState createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _teamSizeController = TextEditingController();
  final _prizeController = TextEditingController();
  
  String? _selectedTurfId;
  String? _selectedSport;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  DateTime _deadline = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TurfProvider>(context, listen: false).fetchMyTurfs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final turfs = Provider.of<TurfProvider>(context).turfs;

    return Scaffold(
      appBar: AppBar(title: const Text('CREATE TOURNAMENT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('BASIC INFO'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTurfId,
                decoration: const InputDecoration(labelText: 'Select Venue'),
                items: turfs.map((turf) {
                  return DropdownMenuItem(value: turf.id, child: Text(turf.name));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTurfId = val;
                    // Auto-select sport if only one available
                    final turf = turfs.firstWhere((t) => t.id == val);
                    if (turf.sports.length == 1) _selectedSport = turf.sports.first;
                  });
                },
                validator: (val) => val == null ? 'Please select a venue' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedTurfId != null) ...[
                DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(labelText: 'Select Sport'),
                  items: turfs.firstWhere((t) => t.id == _selectedTurfId).sports.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSport = val),
                  validator: (val) => val == null ? 'Please select a sport' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tournament Name', hintText: 'e.g. Summer Cup 2026'),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Brief about the tournament'),
                validator: (val) => val!.isEmpty ? 'Description is required' : null,
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('TEAMS & PRICING'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teamSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Team Size',
                        hintText: 'e.g. 5',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxTeamsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Teams',
                        hintText: 'e.g. 16',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Entry Fee (Rs.)',
                        hintText: '0 for free',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _prizeController,
                      decoration: const InputDecoration(
                        labelText: 'Prize Pool',
                        hintText: 'e.g. Rs. 10k + Trophy',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('TIMELINE'),
              const SizedBox(height: 16),
              _buildDatePicker('Start Date', _startDate, (date) => setState(() => _startDate = date)),
              const SizedBox(height: 12),
              _buildDatePicker('End Date', _endDate, (date) => setState(() => _endDate = date)),
              const SizedBox(height: 12),
              _buildDatePicker('Reg. Deadline', _deadline, (date) => setState(() => _deadline = date)),
              
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('CREATE & SUBMIT FOR APPROVAL'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 2),
    );
  }

  Widget _buildDatePicker(String label, DateTime value, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
            Text(
              '${value.day}/${value.month}/${value.year}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final tournamentData = {
      'turfId': _selectedTurfId,
      'sportsType': _selectedSport,
      'name': _nameController.text,
      'description': _descController.text,
      'teamSize': int.parse(_teamSizeController.text),
      'maxTeams': int.parse(_maxTeamsController.text),
      'registrationFee': double.tryParse(_feeController.text) ?? 0.0,
      'prizePool': _prizeController.text,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'registrationDeadline': _deadline.toIso8601String(),
    };
    
    print('DEBUG: Submitting tournament data: $tournamentData');
    final success = await provider.createTournament(tournamentData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament submitted for approval!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create tournament'), backgroundColor: Colors.red),
      );
    }
  }
}
