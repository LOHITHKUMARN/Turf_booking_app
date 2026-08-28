import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../providers/turf_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import '../../../models/turf_model.dart';

class EditTournamentScreen extends StatefulWidget {
  final Tournament tournament;

  const EditTournamentScreen({super.key, required this.tournament});

  @override
  _EditTournamentScreenState createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _feeController;
  late TextEditingController _maxTeamsController;
  late TextEditingController _teamSizeController;
  late TextEditingController _prizeController;
  
  String? _selectedTurfId;
  String? _selectedSport;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _deadline;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tournament.name);
    _descController = TextEditingController(text: widget.tournament.description);
    _feeController = TextEditingController(text: widget.tournament.registrationFee.toString());
    _maxTeamsController = TextEditingController(text: widget.tournament.maxTeams.toString());
    _teamSizeController = TextEditingController(text: widget.tournament.teamSize.toString());
    _prizeController = TextEditingController(text: widget.tournament.prizePool);
    
    _selectedTurfId = widget.tournament.turfId;
    _selectedSport = widget.tournament.sportsType;
    _startDate = widget.tournament.startDate;
    _endDate = widget.tournament.endDate;
    _deadline = widget.tournament.registrationDeadline;
    _status = widget.tournament.status;

    Future.microtask(() {
      Provider.of<TurfProvider>(context, listen: false).fetchMyTurfs();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _feeController.dispose();
    _maxTeamsController.dispose();
    _teamSizeController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfs = Provider.of<TurfProvider>(context).turfs;

    return Scaffold(
      appBar: AppBar(title: const Text('EDIT TOURNAMENT')),
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
                    final turf = turfs.firstWhere((t) => t.id == val);
                    if (!turf.sports.contains(_selectedSport)) {
                      _selectedSport = turf.sports.isNotEmpty ? turf.sports.first : null;
                    }
                  });
                },
                validator: (val) => val == null ? 'Please select a venue' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedTurfId != null && turfs.any((t) => t.id == _selectedTurfId)) ...[
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
                decoration: const InputDecoration(labelText: 'Tournament Name', floatingLabelBehavior: FloatingLabelBehavior.always),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', floatingLabelBehavior: FloatingLabelBehavior.always),
                validator: (val) => val!.isEmpty ? 'Description is required' : null,
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('STATUS'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Tournament Status'),
                items: [
                  const DropdownMenuItem(value: 'open', child: Text('OPEN')),
                  const DropdownMenuItem(value: 'ongoing', child: Text('ONGOING')),
                  const DropdownMenuItem(value: 'completed', child: Text('COMPLETED')),
                  const DropdownMenuItem(value: 'cancelled', child: Text('CANCELLED')),
                ],
                onChanged: (val) => setState(() => _status = val!),
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
                      decoration: const InputDecoration(labelText: 'Team Size', floatingLabelBehavior: FloatingLabelBehavior.always),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxTeamsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maximum Teams', floatingLabelBehavior: FloatingLabelBehavior.always),
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
                      decoration: const InputDecoration(labelText: 'Entry Fee (Rs.)', floatingLabelBehavior: FloatingLabelBehavior.always),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _prizeController,
                      decoration: const InputDecoration(labelText: 'Prize Pool', floatingLabelBehavior: FloatingLabelBehavior.always),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('SAVE CHANGES'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
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
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
      'status': _status,
    };
    
    final success = await provider.updateTournament(widget.tournament.id, tournamentData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to indicate update
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update tournament'), backgroundColor: Colors.red),
      );
    }
  }
}
