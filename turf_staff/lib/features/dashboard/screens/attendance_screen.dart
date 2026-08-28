import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ATTENDANCE',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: staff.isClockedIn 
                            ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                            : [const Color(0xFFFFA726), const Color(0xFFFB8C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (staff.isClockedIn ? const Color(0xFF4CAF50) : const Color(0xFFFB8C00)).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      staff.isClockedIn ? Icons.verified_user_rounded : Icons.timer_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    staff.isClockedIn ? 'YOU ARE CLOCKED IN' : 'YOU ARE CLOCKED OUT',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    staff.isClockedIn && staff.activeAttendance != null
                      ? 'Clocked in at ${DateFormat('hh:mm a').format(DateTime.parse(staff.activeAttendance!['clockIn']).toLocal())}'
                      : 'Punch in to start your shift',
                    style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: staff.isLoading ? null : () async {
                      bool success;
                      if (staff.isClockedIn) {
                        success = await staff.clockOut();
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('CLOCKED OUT SUCCESSFULLY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        }
                      } else {
                        success = await staff.clockIn();
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('CLOCKED IN SUCCESSFULLY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        }
                      }
                      
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(staff.errorMessage ?? 'OPERATION FAILED. RETRY.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: staff.isClockedIn 
                              ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                              : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (staff.isClockedIn ? Colors.red : const Color(0xFF2E7D32)).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: staff.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              staff.isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Shift Details
            if (staff.isClockedIn && staff.activeAttendance != null) ...[
              _buildDetailCard(
                'Current Shift',
                'Started today at ${DateFormat('hh:mm a').format(DateTime.parse(staff.activeAttendance!['clockIn']).toLocal())}',
                Icons.access_time_filled_rounded,
              ),
              const SizedBox(height: 16),
            ],

            _buildDetailCard(
              'Shift Policy',
              'Please ensure you clock out before leaving the premises to ensure accurate logging.',
              Icons.info_outline_rounded,
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String subtitle, IconData icon, {bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSecondary ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(isSecondary ? 0.03 : 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEDF1ED), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
