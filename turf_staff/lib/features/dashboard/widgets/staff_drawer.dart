import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../screens/attendance_screen.dart';
import '../screens/announcement_screen.dart';
import '../screens/report_issue_screen.dart';
import '../screens/productivity_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/safety_screen.dart';
import '../../../providers/staff_provider.dart';

class StaffDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final staff = Provider.of<StaffProvider>(context);
    final isClockedIn = staff.isClockedIn;

    return Drawer(
      backgroundColor: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?['name']?[0]?.toUpperCase() ?? 'S',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user?['name'] ?? 'Staff Member',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?['email'] ?? 'staff@turf.com',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_filled,
                  label: 'Home',
                  onTap: () => Navigator.pop(context),
                  isSelected: true,
                ),
                _buildSectionHeader('ATTENDANCE'),
                _buildDrawerItem(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Clock-In / Out',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen()));
                  },
                ),
                _buildSectionHeader('PRODUCTIVITY'),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Tracking & Stats',
                  enabled: isClockedIn,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductivityScreen()));
                  },
                ),
                _buildSectionHeader('COMMUNICATION'),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_none_rounded,
                  label: 'Announcements',
                  enabled: isClockedIn,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AnnouncementScreen()));
                  },
                ),
                _buildSectionHeader('PAYMENTS'),
                _buildDrawerItem(
                  context,
                  icon: Icons.add_card_rounded,
                  label: 'Extra Charges',
                  enabled: isClockedIn,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentsScreen()));
                  },
                ),
                _buildSectionHeader('SAFETY'),
                _buildDrawerItem(
                  context,
                  icon: Icons.security_rounded,
                  label: 'Reports & Compliance',
                  enabled: isClockedIn,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyScreen()));
                  },
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () => auth.logout(),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  const SizedBox(width: 16),
                  Text(
                    'Logout',
                    style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.black26,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: enabled ? onTap : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF2E7D32)
                : (enabled ? Colors.black54 : Colors.black26),
            size: 22,
          ),
          title: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected
                  ? const Color(0xFF2E7D32)
                  : (enabled ? Colors.black87 : Colors.black26),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          trailing: !enabled
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Coming Soon",
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : (isSelected ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32), size: 20) : null),
        ),
      ),
    );
  }
}
