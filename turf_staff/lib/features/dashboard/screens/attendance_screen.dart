import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  Timer? _tickerTimer;
  DateTime _now = DateTime.now();
  bool _isPolicyDismissed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startLiveTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      staff.fetchActiveAttendance();
      staff.fetchAttendanceHistory();
    });
  }

  void _startLiveTimer() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDurationReadable(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Active attendance info
    DateTime? clockInTime;
    if (staff.isClockedIn && staff.activeAttendance != null) {
      final clockInStr = staff.activeAttendance!['clockIn']?.toString();
      if (clockInStr != null) {
        clockInTime = DateTime.tryParse(clockInStr)?.toLocal();
      }
    }

    final Duration elapsed = clockInTime != null
        ? _now.difference(clockInTime)
        : Duration.zero;

    // Assigned turf / ground from user profile or active attendance
    String venueName = 'Assigned Turf';
    String groundName = 'Ground Staff';
    if (staff.activeAttendance != null) {
      final turf = staff.activeAttendance!['turf'] ?? staff.activeAttendance!['turfId'];
      if (turf is Map && turf['name'] != null) {
        venueName = turf['name'].toString();
      }
      if (staff.activeAttendance!['groundName'] != null &&
          staff.activeAttendance!['groundName'].toString().isNotEmpty) {
        groundName = staff.activeAttendance!['groundName'].toString();
      }
    } else if (auth.user != null) {
      final assignedTurf = auth.user!['assignedTurfId'];
      if (assignedTurf is Map && assignedTurf['name'] != null) {
        venueName = assignedTurf['name'].toString();
      }
      if (auth.user!['assignedGround'] != null &&
          auth.user!['assignedGround'].toString().isNotEmpty) {
        groundName = auth.user!['assignedGround'].toString();
      }
    }

    // Weekly hours calculation from history + live running shift
    double weeklyHours = 0.0;
    final sevenDaysAgo = _now.subtract(const Duration(days: 7));
    for (var item in staff.attendanceHistory) {
      if (item['clockIn'] != null) {
        final dt = DateTime.tryParse(item['clockIn'].toString());
        if (dt != null && dt.isAfter(sevenDaysAgo)) {
          final hrs = (item['workHours'] is num) ? (item['workHours'] as num).toDouble() : 0.0;
          weeklyHours += hrs;
        }
      }
    }
    if (staff.isClockedIn && elapsed > Duration.zero) {
      weeklyHours += (elapsed.inSeconds / 3600.0);
    }

    // Prepare history list, synthesizing active shift at top if not already present
    final List<dynamic> displayHistory = List.from(staff.attendanceHistory);
    if (staff.isClockedIn && staff.activeAttendance != null) {
      final activeId = staff.activeAttendance!['_id'] ?? staff.activeAttendance!['id'];
      final exists = displayHistory.any((h) => (h['_id'] ?? h['id']) == activeId);
      if (!exists) {
        displayHistory.insert(0, {
          ...staff.activeAttendance!,
          'workHours': elapsed.inSeconds / 3600.0,
          'status': 'Active',
          'clockOut': null,
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ATTENDANCE & TIME TRACKER',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00A86B)),
            tooltip: 'Refresh Status',
            onPressed: () {
              staff.fetchActiveAttendance();
              staff.fetchAttendanceHistory();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00A86B),
        onRefresh: () async {
          await staff.fetchActiveAttendance();
          await staff.fetchAttendanceHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Attendance Card
              _buildHeroAttendanceCard(
                staff: staff,
                clockInTime: clockInTime,
                elapsed: elapsed,
                venueName: venueName,
                groundName: groundName,
              ),

              const SizedBox(height: 20),

              // Supplementary Shift Details Card
              if (staff.isClockedIn && clockInTime != null) ...[
                _buildActiveShiftDetailsCard(
                  clockInTime: clockInTime,
                  venueName: venueName,
                  groundName: groundName,
                  elapsed: elapsed,
                ),
                const SizedBox(height: 20),
              ],

              // Weekly Summary Banner
              _buildWeeklySummaryBanner(weeklyHours),

              const SizedBox(height: 20),

              // Recent Shifts List
              _buildRecentShiftsSection(displayHistory),

              const SizedBox(height: 20),

              // Dismissible Shift Policy Card
              if (!_isPolicyDismissed) _buildShiftPolicyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAttendanceCard({
    required StaffProvider staff,
    required DateTime? clockInTime,
    required Duration elapsed,
    required String venueName,
    required String groundName,
  }) {
    final isClockedIn = staff.isClockedIn;
    final liveTimeString = DateFormat('hh:mm:ss a').format(_now);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isClockedIn
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isClockedIn
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // State Badge with Live Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isClockedIn
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isClockedIn
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isClockedIn
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isClockedIn ? 'ON DUTY • CLOCKED IN' : 'OFF DUTY • CLOCKED OUT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isClockedIn
                        ? const Color(0xFF047857)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Central Animated Icon (Time Tracker / Clock)
          ScaleTransition(
            scale: isClockedIn ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isClockedIn
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF64748B), const Color(0xFF475569)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isClockedIn ? const Color(0xFF10B981) : const Color(0xFF64748B))
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isClockedIn ? Icons.access_time_filled_rounded : Icons.fingerprint_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Live Elapsed Timer or Punch-in prompt
          if (isClockedIn) ...[
            Text(
              _formatDuration(elapsed),
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LIVE ELAPSED DURATION',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF10B981),
                letterSpacing: 1.5,
              ),
            ),
          ] else ...[
            Text(
              'READY TO WORK?',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Punch in below to start tracking your shift hours',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Real-time Current Clock & Location Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Current Time: $liveTimeString',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action Button (Clock In or Clock Out with Safety Confirmation)
          GestureDetector(
            onTap: staff.isLoading
                ? null
                : () {
                    if (isClockedIn) {
                      _showClockOutConfirmationSheet(
                        context: context,
                        staff: staff,
                        clockInTime: clockInTime,
                        elapsed: elapsed,
                        venueName: venueName,
                        groundName: groundName,
                      );
                    } else {
                      _handleClockIn(context, staff);
                    }
                  },
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClockedIn
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF00A86B), const Color(0xFF008f5a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isClockedIn ? const Color(0xFFEF4444) : const Color(0xFF00A86B))
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: staff.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftDetailsCard({
    required DateTime clockInTime,
    required String venueName,
    required String groundName,
    required Duration elapsed,
  }) {
    final startTimeStr = DateFormat('hh:mm a').format(clockInTime);
    final startDateStr = DateFormat('MMM dd, yyyy').format(clockInTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE SHIFT DETAILS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDetailItem(
                icon: Icons.access_time_rounded,
                label: 'Started At',
                value: '$startTimeStr\n($startDateStr)',
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              _buildDetailItem(
                icon: Icons.timer_outlined,
                label: 'Running For',
                value: _formatDurationReadable(elapsed),
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetailItem(
                icon: Icons.location_on_outlined,
                label: 'Assigned Venue',
                value: venueName,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(width: 12),
              _buildDetailItem(
                icon: Icons.sports_soccer_outlined,
                label: 'Ground / Area',
                value: groundName.isNotEmpty ? groundName : 'General Venue',
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryBanner(double weeklyHours) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.date_range_rounded, color: Color(0xFF00C853), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAST 7 DAYS HOURS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${weeklyHours.toStringAsFixed(1)} hrs logged',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'PAYROLL VERIFIED',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF38BDF8),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShiftsSection(List<dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RECENT SHIFTS HISTORY',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (history.isNotEmpty)
              Text(
                '${history.length} logged',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.history_rounded, size: 36, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 8),
                  Text(
                    'No completed shifts recorded yet',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your attendance records will appear here after clock out.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final shift = history[index];
              return _buildShiftHistoryItem(shift);
            },
          ),
      ],
    );
  }

  Widget _buildShiftHistoryItem(dynamic shift) {
    DateTime? inTime;
    DateTime? outTime;
    if (shift['clockIn'] != null) {
      inTime = DateTime.tryParse(shift['clockIn'].toString())?.toLocal();
    }
    if (shift['clockOut'] != null) {
      outTime = DateTime.tryParse(shift['clockOut'].toString())?.toLocal();
    }

    final double workHours = (shift['workHours'] is num)
        ? (shift['workHours'] as num).toDouble()
        : 0.0;
    final bool isCompleted = outTime != null;
    final double displayWorkHours = isCompleted
        ? workHours
        : (inTime != null ? (_now.difference(inTime).inSeconds / 3600.0) : 0.0);

    final dateStr = inTime != null
        ? DateFormat('EEE, MMM dd').format(inTime)
        : 'Unknown Date';
    final timeSpanStr = inTime != null
        ? '${DateFormat('hh:mm a').format(inTime)} - ${outTime != null ? DateFormat('hh:mm a').format(outTime) : 'Active Now'}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeSpanStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCompleted
                    ? '${workHours.toStringAsFixed(1)} hrs'
                    : '${displayWorkHours.toStringAsFixed(2)} hrs',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : 'ACTIVE',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isCompleted ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF00A86B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift & Clock-Out Policy',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please ensure you clock out before leaving the venue premises to guarantee accurate payroll calculation and shift logging.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isPolicyDismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleClockIn(BuildContext context, StaffProvider staff) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await staff.clockIn();
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'CLOCKED IN SUCCESSFULLY',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
          ),
          backgroundColor: const Color(0xFF00A86B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            staff.errorMessage ?? 'FAILED TO CLOCK IN. TRY AGAIN.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _showClockOutConfirmationSheet({
    required BuildContext context,
    required StaffProvider staff,
    required DateTime? clockInTime,
    required Duration elapsed,
    required String venueName,
    required String groundName,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final startTimeStr = clockInTime != null
        ? DateFormat('hh:mm a').format(clockInTime)
        : 'N/A';
    final endTimeStr = DateFormat('hh:mm a').format(_now);
    final durationReadable = _formatDurationReadable(elapsed);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRM CLOCK OUT',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'This will finalize your shift record.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Shift Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Shift Started', startTimeStr),
                      const Divider(color: Color(0xFFE2E8F0), height: 16),
                      _buildSummaryRow('Clock Out Time', endTimeStr),
                      const Divider(color: Color(0xFFE2E8F0), height: 16),
                      _buildSummaryRow('Total Duration', durationReadable, isHighlighted: true),
                      const Divider(color: Color(0xFFE2E8F0), height: 16),
                      _buildSummaryRow('Assigned Venue', venueName),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          final success = await staff.clockOut();
                          if (!mounted) return;

                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'CLOCKED OUT SUCCESSFULLY',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                                ),
                                backgroundColor: const Color(0xFF00A86B),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  staff.errorMessage ?? 'FAILED TO CLOCK OUT',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'YES, CLOCK OUT',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
            color: isHighlighted ? const Color(0xFF059669) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
