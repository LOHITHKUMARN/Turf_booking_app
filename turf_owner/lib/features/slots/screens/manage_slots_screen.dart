import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';

import 'package:google_fonts/google_fonts.dart';

class SlotManagementScreen extends StatefulWidget {
  final Turf turf;
  const SlotManagementScreen({super.key, required this.turf});

  @override
  _SlotManagementScreenState createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  String _selectedDay = 'Monday';
  String? _selectedSport;
  String? _selectedGround;
  List<Map<String, dynamic>> _slots = [];
  bool _isSaving = false;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.turf.sports.isNotEmpty ? widget.turf.sports[0] : null;
    _selectedGround = widget.turf.grounds.isNotEmpty ? widget.turf.grounds[0] : '';
    _initializeDefaultSlots();
    _loadExistingSlots();
  }

  void _initializeDefaultSlots() {
    _slots = [];
    for (int i = 6; i < 23; i++) {
        final start = '${i.toString().padLeft(2, '0')}:00';
        final end = '${(i + 1).toString().padLeft(2, '0')}:00';
        _slots.add({
            'dayOfWeek': _selectedDay,
            'sport': _selectedSport,
            'groundName': _selectedGround,
            'startTime': start,
            'endTime': end,
            'price': 1000, // Default price
            'isBlocked': false,
        });
    }
  }

  Future<void> _loadExistingSlots() async {
    final existing = await Provider.of<TurfProvider>(context, listen: false).fetchTurfSlots(widget.turf.id);
    if (existing.isNotEmpty) {
        if (mounted) {
          setState(() {
              // Update default slots with existing data where match found
              for (var slot in _slots) {
                  final match = existing.firstWhere(
                      (e) => e['dayOfWeek'] == _selectedDay && 
                             e['startTime'] == slot['startTime'] &&
                             e['sport'] == _selectedSport &&
                             e['groundName'] == (_selectedGround ?? ''),
                      orElse: () => null
                  );
                  if (match != null) {
                      slot['price'] = match['price'];
                      slot['isBlocked'] = match['isBlocked'];
                  }
              }
          });
        }
    }
  }

  void _save() async {
    setState(() => _isSaving = true);
    final success = await Provider.of<TurfProvider>(context, listen: false).saveSlots(widget.turf.id, _slots);
    if (mounted) setState(() => _isSaving = false);
    
    if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Slots saved for $_selectedDay')));
    } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save slots')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Slots'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.turf.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Select Day',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDay = val!;
                            _initializeDefaultSlots();
                            _loadExistingSlots();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSport,
                        decoration: const InputDecoration(
                          labelText: 'Select Sport',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: widget.turf.sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSport = val;
                            _initializeDefaultSlots();
                            _loadExistingSlots();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.turf.grounds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGround,
                    decoration: const InputDecoration(
                      labelText: 'Select Ground',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: widget.turf.grounds.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGround = val;
                        _initializeDefaultSlots();
                        _loadExistingSlots();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _slots.length,
              itemBuilder: (context, index) {
                final slot = _slots[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time, size: 18, color: Color(0xFF00A86B)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${slot['startTime']} - ${slot['endTime']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Text('Time Slot', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            prefixText: 'Rs. ',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: slot['price'].toString())
                            ..selection = TextSelection.fromPosition(TextPosition(offset: slot['price'].toString().length)),
                          onChanged: (val) => slot['price'] = int.tryParse(val) ?? 0,
                          enabled: !slot['isBlocked'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Switch(
                            value: slot['isBlocked'],
                            onChanged: (val) => setState(() => slot['isBlocked'] = val),
                            activeColor: Colors.red,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(
                            slot['isBlocked'] ? 'Blocked' : 'Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: slot['isBlocked'] ? Colors.red : const Color(0xFF00A86B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('SAVE SLOT CONFIGURATION'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
