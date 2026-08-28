import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';

class WalkInBookingScreen extends StatefulWidget {
  @override
  _WalkInBookingScreenState createState() => _WalkInBookingScreenState();
}

class _WalkInBookingScreenState extends State<WalkInBookingScreen> {
  dynamic _selectedSlot;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<StaffProvider>(context, listen: false).fetchSlots());
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);

    // Grouping slots by time of day for Bento layout
    final morningSlots = staff.slots.where((s) {
      if (s is! Map || s['startTime'] == null) return false;
      final hour = int.parse(s['startTime'].split(':')[0]);
      return hour < 12 && !(s['isBlocked'] ?? false);
    }).toList();
    
    final eveningSlots = staff.slots.where((s) {
      if (s is! Map || s['startTime'] == null) return false;
      final hour = int.parse(s['startTime'].split(':')[0]);
      return hour >= 12 && !(s['isBlocked'] ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5), // Slightly more blue-grey for better contrast
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (staff.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))),
          if (!staff.isLoading) ...[
            _buildAmountInput(),
            if (morningSlots.isNotEmpty) ...[
              _buildSectionHeader("MORNING SLOTS"),
              _buildSlotGrid(morningSlots),
            ],
            if (eveningSlots.isNotEmpty) ...[
              _buildSectionHeader("EVENING SLOTS"),
              _buildSlotGrid(eveningSlots),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedSlot != null && !staff.isLoading
          ? _buildConfirmButton(staff)
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'QUICK BOOKING',
        style: GoogleFonts.outfit(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43A047).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "BOOKING AMOUNT",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 24, 16),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.black.withOpacity(0.4), // Slightly darker for better visibility
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotGrid(List<dynamic> slots) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final slot = slots[index];
            final isSelected = _selectedSlot?['_id'] == slot['_id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? const Color(0xFF2E7D32).withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: isSelected ? 15 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${slot['startTime']} - ${slot['endTime']}',
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 2,
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: slots.length,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(StaffProvider staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () async {
            if (_selectedSlot == null || _amountController.text.isEmpty) return;
            final success = await staff.createWalkInBooking(
              slotId: _selectedSlot['_id'],
              sport: _selectedSlot['sport'],
              totalAmount: double.parse(_amountController.text),
            );
            if (success) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('BOOKING AUTHORIZED!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), // Darker green for premium feel
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            'CONFIRM MATCH',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
