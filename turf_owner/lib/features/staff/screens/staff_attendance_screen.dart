import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/turf_provider.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final dynamic staff;

  const StaffAttendanceScreen({super.key, this.staff});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  dynamic _selectedStaff;
  List<dynamic> _allAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.staff;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialFetch();
      }
    });
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    final provider = Provider.of<TurfProvider>(context, listen: false);
    try {
      await Future.wait([
        provider.fetchStaff(),
        provider.fetchMyTurfs(),
      ]);
    } catch (e) {
      debugPrint('Error fetching initial staff attendance data: $e');
    }
    if (!mounted) return;
    await _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<TurfProvider>(context, listen: false);
      final data = await provider.fetchStaffAttendance();
      if (!mounted) return;
      setState(() {
        _allAttendance = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _displayedAttendance {
    if (_selectedStaff == null) {
      return _allAttendance;
    }
    final selectedId = (_selectedStaff['id'] ?? _selectedStaff['_id'])?.toString();
    if (selectedId == null) return _allAttendance;

    return _allAttendance.where((r) {
      final rawUserId = r['userId'] is Map
          ? (r['userId']['id'] ?? r['userId']['_id'])?.toString()
          : r['userId']?.toString();
      final rawUserObjId = r['user'] is Map
          ? (r['user']['id'] ?? r['user']['_id'])?.toString()
          : null;
      return rawUserId == selectedId || rawUserObjId == selectedId;
    }).toList();
  }

  String _getStaffName(dynamic record, TurfProvider provider) {
    if (record['user'] is Map && record['user']['name'] != null) {
      return record['user']['name'].toString();
    }
    if (record['userId'] is Map && record['userId']['name'] != null) {
      return record['userId']['name'].toString();
    }
    final rawUserId = record['userId']?.toString();
    if (rawUserId != null) {
      for (final s in provider.staff) {
        if (s['id']?.toString() == rawUserId || s['_id']?.toString() == rawUserId) {
          if (s['name'] != null) return s['name'].toString();
        }
      }
    }
    if (_selectedStaff != null && _selectedStaff['name'] != null) {
      return _selectedStaff['name'].toString();
    }
    return 'Staff Member';
  }

  String _getTurfName(dynamic record, TurfProvider provider) {
    String turfName = '';
    if (record['turf'] is Map && record['turf']['name'] != null) {
      turfName = record['turf']['name'].toString();
    } else if (record['turfId'] is Map && record['turfId']['name'] != null) {
      turfName = record['turfId']['name'].toString();
    } else {
      final rawTurfId = record['turfId']?.toString();
      if (rawTurfId != null) {
        for (final t in provider.turfs) {
          if (t.id.toString() == rawTurfId) {
            turfName = t.name;
            break;
          }
        }
      }
    }
    if (turfName.isEmpty) {
      turfName = 'Turf';
    }
    final ground = record['groundName']?.toString();
    if (ground != null && ground.isNotEmpty) {
      turfName = '$turfName ($ground)';
    }
    return turfName;
  }

  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);
    final displayedList = _displayedAttendance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _selectedStaff != null
              ? '${_selectedStaff['name']}\'s Attendance'
              : 'Staff Attendance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () {
            if (_selectedStaff != null && widget.staff == null) {
              setState(() => _selectedStaff = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00A86B)),
            tooltip: 'Refresh',
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A86B)))
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              color: const Color(0xFF00A86B),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // 1. Staff Selector Chips
                  _buildStaffFilterBar(turfProvider),
                  const SizedBox(height: 16),

                  // 2. If a specific staff is selected: Show their profile summary card
                  if (_selectedStaff != null) ...[
                    _buildSelectedStaffSummaryCard(turfProvider, displayedList),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Attendance History (${displayedList.length})',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => _selectedStaff = null),
                          child: const Text('View All Staff', style: TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // If no staff is selected: Show the Staff Directory cards first
                    _buildStaffDirectorySection(turfProvider),
                    const SizedBox(height: 24),
                    Text(
                      'All Recent Attendance Logs (${displayedList.length})',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. Attendance Cards List
                  if (displayedList.isEmpty)
                    _buildEmptyState()
                  else
                    ...displayedList.map((record) => _buildAttendanceCard(record, turfProvider)),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStaffFilterBar(TurfProvider turfProvider) {
    final staffList = turfProvider.staff;
    final isAllSelected = _selectedStaff == null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All Staff" chip
          GestureDetector(
            onTap: () => setState(() => _selectedStaff = null),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAllSelected ? const Color(0xFF00A86B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isAllSelected ? const Color(0xFF00A86B) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isAllSelected
                    ? [BoxShadow(color: const Color(0xFF00A86B).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 16,
                    color: isAllSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Staff (${_allAttendance.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isAllSelected ? FontWeight.bold : FontWeight.w500,
                      color: isAllSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chips for each individual staff member
          ...staffList.map((staff) {
            final staffId = (staff['id'] ?? staff['_id'])?.toString();
            final isSelected = _selectedStaff != null &&
                ((_selectedStaff['id'] ?? _selectedStaff['_id'])?.toString() == staffId);

            // Check if this staff has active attendance
            final hasActiveClockIn = _allAttendance.any((r) {
              final rId = r['userId'] is Map ? (r['userId']['id'] ?? r['userId']['_id'])?.toString() : r['userId']?.toString();
              return rId == staffId && r['clockOut'] == null;
            });

            return GestureDetector(
              onTap: () => setState(() => _selectedStaff = staff),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00A86B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00A86B) : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF00A86B).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: isSelected ? Colors.white : const Color(0xFF00A86B).withValues(alpha: 0.15),
                      child: Text(
                        (staff['name'] != null && staff['name'].toString().isNotEmpty)
                            ? staff['name'].toString()[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF00A86B) : const Color(0xFF00A86B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      staff['name'] ?? 'Staff',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    if (hasActiveClockIn) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.yellowAccent : const Color(0xFF00A86B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStaffDirectorySection(TurfProvider turfProvider) {
    final staffList = turfProvider.staff;
    if (staffList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Select Staff to View Attendance',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tap card',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...staffList.map((staff) {
          final staffId = (staff['id'] ?? staff['_id'])?.toString();
          final staffRecords = _allAttendance.where((r) {
            final rId = r['userId'] is Map ? (r['userId']['id'] ?? r['userId']['_id'])?.toString() : r['userId']?.toString();
            return rId == staffId;
          }).toList();

          final bool isClockedIn = staffRecords.any((r) => r['clockOut'] == null);
          final String assignedTurf = staff['assignedTurfId'] is Map
              ? staff['assignedTurfId']['name']?.toString() ?? 'Assigned'
              : (staff['assignedTurfId'] != null ? 'Assigned' : 'Not assigned');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _selectedStaff = staff),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF00A86B).withValues(alpha: 0.12),
                        child: Text(
                          (staff['name'] != null && staff['name'].toString().isNotEmpty)
                              ? staff['name'].toString()[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A86B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['name'] ?? 'Staff',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Turf: $assignedTurf${staff['assignedGround'] != null && staff['assignedGround'] != '' ? ' (${staff['assignedGround']})' : ''}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isClockedIn
                                        ? const Color(0xFF00A86B).withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isClockedIn ? const Color(0xFF00A86B) : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isClockedIn ? 'CLOCKED IN' : 'OFF DUTY',
                                        style: TextStyle(
                                          color: isClockedIn ? const Color(0xFF00A86B) : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${staffRecords.length} shifts',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF00A86B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedStaffSummaryCard(TurfProvider turfProvider, List<dynamic> staffRecords) {
    double totalHours = 0.0;
    bool isCurrentlyClockedIn = false;

    for (final r in staffRecords) {
      if (r['clockOut'] == null) {
        isCurrentlyClockedIn = true;
      }
      final double hours = (r['workHours'] is num)
          ? (r['workHours'] as num).toDouble()
          : double.tryParse(r['workHours']?.toString() ?? '0') ?? 0.0;
      totalHours += hours;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00A86B).withValues(alpha: 0.12),
                child: Text(
                  (_selectedStaff['name'] != null && _selectedStaff['name'].toString().isNotEmpty)
                      ? _selectedStaff['name'].toString()[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStaff['name'] ?? 'Staff',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedStaff['email'] ?? _selectedStaff['phone'] ?? 'Ground Staff',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentlyClockedIn
                      ? const Color(0xFF00A86B).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isCurrentlyClockedIn ? const Color(0xFF00A86B) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCurrentlyClockedIn ? 'CLOCKED IN' : 'OFF DUTY',
                      style: TextStyle(
                        color: isCurrentlyClockedIn ? const Color(0xFF00A86B) : Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStatItem('TOTAL SHIFTS', '${staffRecords.length}', Icons.calendar_today_outlined, Colors.blue),
              ),
              Expanded(
                child: _buildSummaryStatItem('TOTAL HOURS', '${totalHours.toStringAsFixed(1)}h', Icons.timelapse_rounded, Colors.purple),
              ),
              Expanded(
                child: _buildSummaryStatItem(
                  'LATEST STATUS',
                  isCurrentlyClockedIn ? 'Active' : 'Completed',
                  isCurrentlyClockedIn ? Icons.login_rounded : Icons.check_circle_outline,
                  isCurrentlyClockedIn ? const Color(0xFF00A86B) : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1A1A1A)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(dynamic record, TurfProvider provider) {
    DateTime clockIn;
    try {
      clockIn = DateTime.parse(record['clockIn'].toString()).toLocal();
    } catch (_) {
      clockIn = DateTime.now();
    }

    DateTime? clockOut;
    if (record['clockOut'] != null) {
      try {
        clockOut = DateTime.parse(record['clockOut'].toString()).toLocal();
      } catch (_) {
        clockOut = null;
      }
    }

    final double duration = (record['workHours'] is num)
        ? (record['workHours'] as num).toDouble()
        : double.tryParse(record['workHours']?.toString() ?? '0') ?? 0.0;

    final status = record['status']?.toString() ?? 'Present';
    final isClockedIn = clockOut == null;

    final staffName = _getStaffName(record, provider);
    final turfName = _getTurfName(record, provider);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClockedIn ? const Color(0xFF00A86B).withValues(alpha: 0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isClockedIn
                ? const Color(0xFF00A86B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF00A86B).withValues(alpha: 0.12),
                        child: Text(
                          staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: Color(0xFF00A86B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffName,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1A1A1A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${DateFormat('EEEE, dd MMM').format(clockIn)} • $turfName',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClockedIn
                        ? const Color(0xFF00A86B).withValues(alpha: 0.12)
                        : (status == 'Late'
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isClockedIn ? 'CLOCKED IN' : status.toUpperCase(),
                    style: TextStyle(
                      color: isClockedIn
                          ? const Color(0xFF00A86B)
                          : (status == 'Late' ? Colors.red : Colors.green),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo('CLOCK IN', DateFormat('hh:mm a').format(clockIn), Icons.login_rounded, Colors.blue),
                ),
                Expanded(
                  child: _buildTimeInfo(
                    'CLOCK OUT',
                    clockOut != null ? DateFormat('hh:mm a').format(clockOut) : '--:--',
                    Icons.logout_rounded,
                    isClockedIn ? Colors.grey : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildTimeInfo(
                    'DURATION',
                    isClockedIn ? 'In progress' : '${duration.toStringAsFixed(1)}h',
                    Icons.timer_outlined,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A1A1A)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 70, color: Colors.green[100]),
            const SizedBox(height: 16),
            Text(
              _selectedStaff != null
                  ? 'No attendance records for ${_selectedStaff['name']}'
                  : 'No attendance logs found',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Staff hasn\'t clocked in yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
