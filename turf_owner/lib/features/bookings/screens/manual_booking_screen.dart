import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';
import '../../../core/theme/app_theme.dart';

class ManualBookingScreen extends StatefulWidget {
  const ManualBookingScreen({super.key});

  @override
  _ManualBookingScreenState createState() => _ManualBookingScreenState();
}

class _ManualBookingScreenState extends State<ManualBookingScreen> {
  Turf? _selectedTurf;
  String? _selectedGround;
  String? _selectedSport;
  dynamic _selectedSlot;
  final TextEditingController _amountController = TextEditingController();
  List<dynamic> _slots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
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
          return match && !(s['isBlocked'] ?? false);
        }).toList();
        _isLoadingSlots = false;
        _selectedSlot = null;
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
          'MANUAL BOOKING',
          style: GoogleFonts.outfit(
            color: AppTheme.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionSection(turfProvider),
            if (_selectedTurf != null) ...[
              _buildAmountInput(),
              _buildSectionHeader("SELECT SLOT"),
              if (_isLoadingSlots)
                const Center(child: Padding(
                  padding: EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ))
              else if (_slots.isEmpty)
                _buildEmptySlotsState()
              else
                _buildSlotGrid(),
              const SizedBox(height: 140),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedSlot != null && !turfProvider.isLoading
          ? _buildConfirmButton(turfProvider)
          : null,
    );
  }

  Widget _buildSelectionSection(TurfProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            label: "CHOOSE TURF",
            value: _selectedTurf,
            items: provider.turfs.map((t) => DropdownMenuItem(
              value: t, 
              child: Text(t.name.toUpperCase())
            )).toList(),
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
              style: GoogleFonts.outfit(color: AppTheme.textMain, fontWeight: FontWeight.w700, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.02), blurRadius: 10)
          ],
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CUSTOM RATE (RS)",
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMain,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.outfit(color: AppTheme.primaryColor),
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 24, 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppTheme.textSecondary.withOpacity(0.2),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildEmptySlotsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              "NO AVAILABLE SLOTS",
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final isSelected = _selectedSlot?['_id'] == slot['_id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
              _amountController.text = slot['price'].toString();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.01), blurRadius: 10)
              ],
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${slot['startTime']} - ${slot['endTime']}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppTheme.textMain,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${slot['price']}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton(TurfProvider turfProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: turfProvider.isLoading ? null : () async {
            if (_selectedSlot == null || _amountController.text.isEmpty) return;
            final success = await turfProvider.createManualBooking(
              turfId: _selectedTurf!.id,
              slotId: _selectedSlot['_id'],
              sport: _selectedSlot['sport'],
              totalAmount: double.parse(_amountController.text),
            );
            if (success) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('BOOKING SECURED!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: turfProvider.isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                'LOCK BOOKING',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
        ),
      ),
    );
  }
}
