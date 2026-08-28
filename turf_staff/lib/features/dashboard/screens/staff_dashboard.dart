import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/staff_provider.dart';
import 'staff_slot_management.dart';
import 'walk_in_booking_screen.dart';
import 'report_issue_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_screen.dart';
import 'announcement_screen.dart';
import '../widgets/extra_charges_dialog.dart';
import '../widgets/staff_drawer.dart';
import '../widgets/premium_button.dart';
import '../widgets/scale_button.dart';
import '../../tournaments/screens/staff_matches_screen.dart';
import '../../../core/services/socket_service.dart';

class StaffDashboard extends StatefulWidget {
  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      staff.fetchAssignedBookings();
      staff.fetchStats();
      staff.fetchActiveAttendance();
    });
    
    // Refresh UI every minute for session timers
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });

    // Listen for real-time announcements
    SocketService().on('newAnnouncement', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📣 ${data['title']}: ${data['content']}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService().off('newAnnouncement');
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final staff = Provider.of<StaffProvider>(context);
    final assignedTurfId = auth.user?['assignedTurfId'];

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    final filteredBookings = staff.todayBookings.where((booking) {
      if (booking['bookingDate'] == null) return false;
      try {
        final bDate = DateTime.parse(booking['bookingDate']).toLocal();
        return DateFormat('yyyy-MM-dd').format(bDate) == todayStr;
      } catch (e) {
        return false;
      }
    }).toList();

    return Scaffold(
      drawer: StaffDrawer(),
      backgroundColor: const Color(0xFFF3F5F4), 
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          staff.fetchAssignedBookings(),
          staff.fetchActiveAttendance(),
          staff.fetchStats(),
        ]),
        backgroundColor: Colors.white,
        color: const Color(0xFF4CAF50),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildPremiumHeader(),
            SliverToBoxAdapter(
              child: assignedTurfId == null
                  ? _buildNoTurfMessage()
                  : !staff.isClockedIn
                      ? _buildClockInRequiredMessage()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDashboardHeader(auth),
                            _buildDashboardActions(staff),
                            _buildTimelineHeader(filteredBookings.length),
                          ],
                        ),
            ),
            if (assignedTurfId != null && staff.isClockedIn)
              (staff.isLoading && filteredBookings.isEmpty)
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))))
                  : filteredBookings.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildTimelineItem(filteredBookings[index], index == filteredBookings.length - 1),
                              childCount: filteredBookings.length,
                            ),
                          ),
                        ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: (assignedTurfId != null && staff.isClockedIn) 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ScaleButton(
                onTap: () => _showGroundStatusDialog(staff),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terrain_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'GROUND',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ScaleButton(
                onTap: _navigateToReportIssue,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'REPORT',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : null,
    );
  }

  Widget _buildPremiumHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF43A047),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Text(
              "CONTROL",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnnouncementScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  auth.user?['name']?[0]?.toUpperCase() ?? 'S',
                  style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.user?['name'] ?? 'Staff Member',
                    style: GoogleFonts.outfit(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildBentoBadge(auth.user?['assignedTurfId'] != null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardActions(StaffProvider staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // 🔥 SLOTS (FULL WIDTH)
          _buildWideCard(
            title: "SLOTS",
            subtitle: "Availability",
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StaffSlotManagementScreen())),
            stats: "${staff.todayBookings.length} Booked / 16",
          ),
          const SizedBox(height: 16),
          // 🔹 SCAN + VERIFY ID + ADD (ROW)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSmallCard(
                  "SCAN",
                  Icons.qr_code_scanner_rounded,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => QRScannerScreen())),
                ),
                const SizedBox(width: 16),
                _buildSmallCard(
                  "VERIFY ID",
                  Icons.pin_rounded,
                  Colors.blue,
                  () => _showVerifyIdDialog(staff),
                ),
                const SizedBox(width: 16),
                _buildSmallCard(
                  "ADD",
                  Icons.add_rounded,
                  const Color(0xFF43A047),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => WalkInBookingScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 🏆 TROPHY (FULL WIDTH)
          _buildWideCard(
            title: "TROPHY",
            subtitle: "Matches",
            icon: Icons.emoji_events_rounded,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffMatchesScreen())),
            stats: "Active Matches",
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? stats,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      stats,
                      style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: child,
    );
  }

  Widget _buildGroundStatusAction(StaffProvider staff) {
    return GestureDetector(
      onTap: () => _showGroundStatusDialog(staff),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terrain_rounded, color: const Color(0xFF4CAF50), size: 18),
            const SizedBox(width: 8),
            Text(
              'GROUND',
              style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyIdDialog(StaffProvider staff) {
    final TextEditingController _idController = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Manual Verification',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Verification',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Enter Booking ID (last 6 characters)",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _inputBox(
                  child: TextField(
                    controller: _idController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. F6A2D1',
                      hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.black26),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final input = _idController.text.trim();
                          if (input.isEmpty) return;
                          
                          final booking = staff.findBookingByShortId(input);
                          if (booking != null) {
                            Navigator.pop(context); // Close entry dialog
                            _showConfirmVerificationDialog(staff, booking);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No booking found matching "$input"', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'SEARCH',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showConfirmVerificationDialog(StaffProvider staff, dynamic booking) {
    final bool isUserPopulated = booking['userId'] is Map;
    final String userName = booking['userId'] == null ? 'WALK-IN PLAYER' : (isUserPopulated ? (booking['userId']['name'] ?? 'GUEST') : 'GUEST');
    final bool isSlotPopulated = booking['slotId'] is Map;
    final String time = isSlotPopulated ? '${booking['slotId']['startTime']} - ${booking['slotId']['endTime']}' : 'N/A';
    final String bookingIdShort = booking['_id'].toString().substring(booking['_id'].toString().length - 6).toUpperCase();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm Player',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_pin_rounded, color: Color(0xFF4CAF50), size: 40),
                ),
                const SizedBox(height: 24),
                Text('CONFIRM PLAYER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: Colors.black38)),
                const SizedBox(height: 12),
                Text(userName, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                _inputBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.black45),
                      const SizedBox(width: 8),
                      Text(time, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('ID: $bookingIdShort', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('BACK', style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context); // Close confirm dialog
                          
                          // Show loading
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: 'Loading',
                            barrierColor: Colors.black.withOpacity(0.4),
                            transitionDuration: const Duration(milliseconds: 200),
                            pageBuilder: (context, anim1, anim2) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                            ),
                          );

                          final success = await staff.verifyBooking(booking['_id']);
                          
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop(); // Close loading
                          }

                          if (success) {
                            _showSuccessDialog();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to verify booking. Please try again.')),
                            );
                          }
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VERIFY',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 80),
                const SizedBox(height: 24),
                Text('VERIFIED!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Text(
                  'Booking confirmed. Match started.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.black45, fontSize: 14),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'DONE',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  void _showGroundStatusDialog(StaffProvider staff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GROUND STATUS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
            const SizedBox(height: 24),
            _buildStatusOption(context, staff, 'normal', 'Normal', Icons.check_circle_outline_rounded, Colors.green),
            _buildStatusOption(context, staff, 'wet', 'Wet / Slippery', Icons.water_drop_rounded, Colors.blue),
            _buildStatusOption(context, staff, 'maintenance', 'Under Maintenance', Icons.build_rounded, Colors.orange),
            _buildStatusOption(context, staff, 'heavy-rain', 'Heavily Rained', Icons.cloudy_snowing, Colors.indigo),
            _buildStatusOption(context, staff, 'power-issue', 'Power Issue', Icons.flash_off_rounded, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, StaffProvider staff, String value, String label, IconData icon, Color color) {
    return ListTile(
      onTap: () async {
        await staff.updateTargetTurfStatus(value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ground marked as $label', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
    );
  }

  Widget _buildBentoBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        active ? '● ONLINE' : '● OFFLINE',
        style: GoogleFonts.outfit(
          color: active ? const Color(0xFF4CAF50) : Colors.black26,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }



  Widget _buildTimelineHeader(int count) {
    final String dateStr = DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: GoogleFonts.outfit(
              color: Colors.black.withOpacity(0.4), // Higher contrast for date
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upcoming Games",
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic booking, bool isLast) {
    if (booking is! Map) return const SizedBox.shrink();
    final String status = booking['bookingStatus'] ?? 'pending';
    final bool isWalkIn = booking['userId'] == null;
    final Color statusColor = _getLightStatusColor(status);
    final bool isUserPopulated = booking['userId'] is Map;
    final String userName = isWalkIn ? 'WALK-IN PLAYER' : (isUserPopulated ? (booking['userId']['name'] ?? 'GUEST') : 'GUEST');
    
    final bool isSlotPopulated = booking['slotId'] is Map;
    final String startTime = isSlotPopulated ? booking['slotId']['startTime'] : 'N/A';
    final String endTime = isSlotPopulated ? booking['slotId']['endTime'] : 'N/A';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Marker
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          // Content Card
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startTime,
                    style: GoogleFonts.outfit(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border.all(color: Colors.black.withOpacity(0.1), width: 1), // Defined border
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${booking['totalAmount']}',
                              style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Ends at $endTime',
                              style: GoogleFonts.outfit(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (status == 'checked-in') _buildSessionTimer(booking),
                          ],
                        ),
                        if (booking['staffNotes'] != null && booking['staffNotes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.sticky_note_2_rounded, size: 14, color: Colors.black26),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking['staffNotes'],
                                    style: GoogleFonts.outfit(color: Colors.black54, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (booking['extraCharges'] != null && booking['extraCharges'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withOpacity(0.03)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EXTRA CHARGES',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                ... (booking['extraCharges'] as List).map((charge) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: charge['isPaid'] ? const Color(0xFF4CAF50) : Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${charge['type']}: Rs. ${charge['amount']}',
                                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildTimelineActions(booking, status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimer(dynamic booking) {
    if (booking['checkInTime'] == null) return const SizedBox.shrink();
    
    final checkIn = DateTime.parse(booking['checkInTime']);
    // Slots are usually 1 hour, let's assume 1 hour if not specified
    final duration = const Duration(hours: 1); 
    final endTime = checkIn.add(duration);
    final now = DateTime.now();
    final remaining = endTime.difference(now);
    
    final bool isOverstay = remaining.isNegative;
    final Color color = isOverstay ? Colors.red : (remaining.inMinutes < 10 ? Colors.orange : const Color(0xFF4CAF50));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOverstay ? Icons.warning_amber_rounded : Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isOverstay 
              ? '+${remaining.abs().inMinutes}m OVER' 
              : '${remaining.inMinutes}m LEFT',
            style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineActions(dynamic booking, String status) {
    if (status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: ScaleButton(
              onTap: () => _showVerificationOptions(booking),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'VERIFY MATCH',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            Icons.cancel_outlined, 
            () => _showCancelConfirmation(booking),
            color: Colors.redAccent,
          ),
        ],
      );
    }
    if (status == 'checked-in') {
      return Row(
        children: [
          Expanded(
            child: _buildTimelineOutlineAction(
              'FINISH',
              () => _handleStatusUpdate(booking['_id'], 'completed'),
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(Icons.sticky_note_2_rounded, () => _showAddNoteDialog(booking)),
          const SizedBox(width: 8),
          _buildActionButton(Icons.add_card_rounded, () => showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Extra Charge',
            barrierColor: Colors.black.withOpacity(0.4),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) => ExtraChargesDialog(booking: booking),
            transitionBuilder: (context, anim1, anim2, child) {
              return Transform.scale(
                scale: anim1.value,
                child: Opacity(
                  opacity: anim1.value,
                  child: child,
                ),
              );
            },
          )),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildTimelineOutlineAction(String label, VoidCallback onTap, Color color) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {Color color = const Color(0xFF4CAF50)}) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showCancelConfirmation(dynamic booking) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cancel Booking',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CANCEL BOOKING?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to mark this booking as a no-show? This action cannot be undone.',
                  style: GoogleFonts.outfit(color: Colors.black54, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('WAIT', style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await _handleStatusUpdate(booking['_id'], 'no-show');
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'YES, CANCEL',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  void _showVerificationOptions(dynamic booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOOSE VERIFICATION',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a method to verify the player\'s match',
              style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRScannerScreen(expectedBookingId: booking['_id'])),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.purple),
              ),
              title: Text('SCAN QR CODE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Fastest for mobile app users', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black26)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                final staff = Provider.of<StaffProvider>(context, listen: false);
                _showVerifyIdDialogForSpecificBooking(staff, booking);
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.pin_rounded, color: Colors.blue),
              ),
              title: Text('MANUAL ID ENTRY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Enter last 6 digits of match ID', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black26)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showVerifyIdDialogForSpecificBooking(StaffProvider staff, dynamic booking) {
    final TextEditingController _idController = TextEditingController();
    final String actualShortId = booking['_id'].toString().substring(booking['_id'].toString().length - 6).toUpperCase();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Verify ID',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Match ID',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Enter Match ID for verification",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _inputBox(
                  child: TextField(
                    controller: _idController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. $actualShortId',
                      hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.black26),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final input = _idController.text.trim().toUpperCase();
                          if (input.isEmpty) return;
                          
                          if (input == actualShortId) {
                            Navigator.pop(context); // Close entry dialog
                            _showConfirmVerificationDialog(staff, booking);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Incorrect ID. This match ID is $actualShortId', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VERIFY',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  void _showAddNoteDialog(dynamic booking) {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    final _noteController = TextEditingController(text: booking['staffNotes'] ?? '');
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Staff Notes',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Notes',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                _inputBox(
                  child: TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add internal match notes...',
                      hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    await staff.addStaffNote(booking['_id'], _noteController.text);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SAVE NOTES',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  Color _getLightStatusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF81C784); // Lite Grass
      case 'checked-in': return const Color(0xFF4CAF50); // Vibrant Grass
      case 'completed': return Colors.black12;
      case 'no-show': return Colors.black.withOpacity(0.1); 
      case 'cancelled': return Colors.black.withOpacity(0.2);
      default: return Colors.grey;
    }
  }

  Widget _buildNoTurfMessage() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_rounded, size: 80, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text(
            'LOCKED',
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Awaiting credentials assignment',
            style: GoogleFonts.outfit(color: Colors.black26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildClockInRequiredMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF43A047),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          Text(
            'CLOCK-IN REQUIRED',
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please clock in from the attendance section to manage bookings and start your shift.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          PremiumButton(
            label: "GO TO ATTENDANCE",
            icon: Icons.fingerprint_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 80, color: Colors.black.withOpacity(0.02)),
              const SizedBox(height: 16),
              Text(
                'NO BOOKINGS FOR TODAY',
                style: GoogleFonts.outfit(color: Colors.black.withOpacity(0.1), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductivityStats(StaffProvider staff) {
    if (staff.stats == null) return const SizedBox.shrink();
    
    final stats = staff.stats!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('HANDLED', stats['handledBookings']?.toString() ?? '0', Icons.check_circle_rounded),
          const SizedBox(width: 12),
          _buildStatItem('RESOLVED', stats['resolvedIssues']?.toString() ?? '0', Icons.build_circle_rounded),
          const SizedBox(width: 12),
          _buildStatItem('SCORE', stats['feedbackScore']?.toString() ?? '0', Icons.star_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReportIssue() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => ReportIssueScreen())
    );
  }

  Future<void> _handleStatusUpdate(String id, String status) async {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    bool success;
    if (status == 'checked-in') {
      success = await staff.verifyBooking(id);
    } else {
      success = await staff.updateBookingStatus(id, status);
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('STATUS: $status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }
}
