import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/staff_provider.dart';

class StaffSlotManagementScreen extends StatefulWidget {
  @override
  _StaffSlotManagementScreenState createState() => _StaffSlotManagementScreenState();
}

class _StaffSlotManagementScreenState extends State<StaffSlotManagementScreen> {
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
      return hour < 12;
    }).toList();
    
    final eveningSlots = staff.slots.where((s) {
      if (s is! Map || s['startTime'] == null) return false;
      final hour = int.parse(s['startTime'].split(':')[0]);
      return hour >= 12;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildBentoSlotAppBar(),
          SliverToBoxAdapter(
            child: staff.isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))))
                : staff.slots.isEmpty
                    ? _buildEmptyState()
                    : const SizedBox.shrink(),
          ),
          if (!staff.isLoading && morningSlots.isNotEmpty) ...[
            _buildSectionLabel("MORNING SESSIONS"),
            _buildBentoSlotGrid(morningSlots),
          ],
          if (!staff.isLoading && eveningSlots.isNotEmpty) ...[
            _buildSectionLabel("EVENING SESSIONS"),
            _buildBentoSlotGrid(eveningSlots),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBentoSlotAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4CAF50),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'GRID CONTROL',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.black26,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildBentoSlotGrid(List<dynamic> slots) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildBentoSlotCard(slots[index]),
          childCount: slots.length,
        ),
      ),
    );
  }

  Widget _buildBentoSlotCard(dynamic slot) {
    final bool isBlocked = slot['isBlocked'] ?? false;
    final Color accentColor = isBlocked ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50);

    return GestureDetector(
      onTap: () => _toggleBlock(slot['_id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isBlocked ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: accentColor.withOpacity(0.5),
                  size: 18,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              slot['startTime'],
              style: GoogleFonts.outfit(
                color: isBlocked ? Colors.black26 : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              slot['sport']?.toString().toUpperCase() ?? 'N/A',
              style: GoogleFonts.outfit(
                color: accentColor.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.layers_clear_rounded, size: 80, color: Colors.black.withOpacity(0.02)),
            const SizedBox(height: 16),
            Text(
              'NO ACTIVE GRID',
              style: GoogleFonts.outfit(color: Colors.black.withOpacity(0.05), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBlock(String slotId) async {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    final success = await staff.toggleSlotBlock(slotId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GRID UPDATED', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      );
    }
  }
}
