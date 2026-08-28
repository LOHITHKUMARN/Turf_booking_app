import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';
import '../../../core/theme/app_theme.dart';

class BlockSlotScreen extends StatefulWidget {
  const BlockSlotScreen({super.key});

  @override
  _BlockSlotScreenState createState() => _BlockSlotScreenState();
}

class _BlockSlotScreenState extends State<BlockSlotScreen> {
  Turf? _selectedTurf;
  String? _selectedGround;
  String? _selectedSport;
  String _selectedDay = 'Monday';
  List<dynamic> _slots = [];
  bool _isLoadingSlots = false;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    final today = DateFormat('EEEE').format(DateTime.now());
    if (_days.contains(today)) {
      _selectedDay = today;
    }
    
    final turfProvider = Provider.of<TurfProvider>(context, listen: false);
    if (turfProvider.turfs.isNotEmpty) {
      _selectedTurf = turfProvider.turfs.first;
      if (_selectedTurf!.grounds.isNotEmpty) {
        _selectedGround = _selectedTurf!.grounds.first;
      }
      if (_selectedTurf!.sports.isNotEmpty) {
        _selectedSport = _selectedTurf!.sports.first;
      }
      _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedTurf == null) return;
    setState(() => _isLoadingSlots = true);
    final slots = await Provider.of<TurfProvider>(context, listen: false)
        .fetchTurfSlots(_selectedTurf!.id);
    
    if (mounted) {
      setState(() {
        _slots = slots.where((s) {
          bool match = true;
          if (_selectedGround != null && _selectedGround!.isNotEmpty) {
            match = s['groundName'] == _selectedGround;
          }
          if (_selectedSport != null && _selectedSport!.isNotEmpty) {
            match = match && s['sport'] == _selectedSport;
          }
          if (_selectedDay.isNotEmpty) {
            match = match && s['dayOfWeek'] == _selectedDay;
          }
          return match;
        }).toList();
        _isLoadingSlots = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BLOCK SLOTS',
          style: GoogleFonts.outfit(
            color: AppTheme.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectionSection(turfProvider),
          _buildDaySelector(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              children: [
                Container(width: 4, height: 12, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(
                  "TAP TO TOGGLE STATUS",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _slots.isEmpty
                    ? _buildEmptySlotsState()
                    : _buildSlotGrid(turfProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDay = day);
                _loadSlots();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.01), blurRadius: 10)
                  ],
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.black.withOpacity(0.05)),
                ),
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 11,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionSection(TurfProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown<Turf>(
            label: "CHOOSE VENUE",
            value: _selectedTurf,
            items: provider.turfs.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedTurf = val;
                _selectedGround = _selectedTurf?.grounds.isNotEmpty == true ? _selectedTurf!.grounds.first : null;
                _selectedSport = _selectedTurf?.sports.isNotEmpty == true ? _selectedTurf!.sports.first : null;
              });
              _loadSlots();
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_selectedTurf != null && _selectedTurf!.grounds.isNotEmpty)
                Expanded(
                  child: _buildDropdown<String>(
                    label: "GROUND",
                    value: _selectedGround,
                    items: _selectedTurf!.grounds.map((g) => DropdownMenuItem(value: g, child: Text(g.toUpperCase()))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedGround = val);
                      _loadSlots();
                    },
                  ),
                ),
              if (_selectedTurf != null && _selectedTurf!.grounds.isNotEmpty)
                const SizedBox(width: 16),
              if (_selectedTurf != null)
                Expanded(
                  child: _buildDropdown<String>(
                    label: "SPORT",
                    value: _selectedSport,
                    items: _selectedTurf!.sports.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSport = val);
                      _loadSlots();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: GoogleFonts.outfit(color: AppTheme.textMain, fontWeight: FontWeight.w800, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlotsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            "NO SLOTS FOUND",
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(TurfProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final isBlocked = slot['isBlocked'] ?? false;
        
        return GestureDetector(
          onTap: () async {
            final success = await provider.toggleSlotBlock(slot['_id']);
            if (success) {
              _loadSlots();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.redAccent.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isBlocked ? Colors.redAccent : Colors.black.withOpacity(0.05),
                width: isBlocked ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: isBlocked ? Colors.redAccent.withOpacity(0.05) : Colors.black.withOpacity(0.01), blurRadius: 10)
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.redAccent : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${slot['startTime']} - ${slot['endTime']}',
                        style: GoogleFonts.outfit(
                          color: isBlocked ? Colors.redAccent : AppTheme.textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBlocked ? "BLOCKED" : "LIVE",
                        style: GoogleFonts.outfit(
                          color: isBlocked ? Colors.redAccent.withOpacity(0.5) : AppTheme.textSecondary.withOpacity(0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
