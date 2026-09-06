import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';

class StaffReportsScreen extends StatefulWidget {
  const StaffReportsScreen({super.key});

  @override
  State<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends State<StaffReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = 'ALL';
  String? _selectedTurfId; // null means all turfs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = Provider.of<TurfProvider>(context, listen: false);
    provider.fetchOwnerReports();
    if (provider.turfs.isEmpty) {
      provider.fetchMyTurfs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TurfProvider>(context);
    final maintenances = provider.maintenances;
    final incidents = provider.incidents;

    // Filter by Turf
    final filteredMaintenances = maintenances.where((item) {
      if (_selectedTurfId == null) return true;
      final turfVal = item['turfId'];
      final tId = turfVal is Map ? (turfVal['_id'] ?? turfVal['id']) : turfVal;
      return tId?.toString() == _selectedTurfId;
    }).toList();

    final filteredIncidents = incidents.where((item) {
      if (_selectedTurfId == null) return true;
      final turfVal = item['turfId'];
      final tId = turfVal is Map ? (turfVal['_id'] ?? turfVal['id']) : turfVal;
      return tId?.toString() == _selectedTurfId;
    }).toList();

    // Calculate metrics
    final totalCount = filteredMaintenances.length + filteredIncidents.length;
    final pendingCount = filteredMaintenances
            .where((m) => (m['status'] ?? 'Pending') == 'Pending')
            .length +
        filteredIncidents
            .where((i) => (i['status'] ?? 'Reported') == 'Reported')
            .length;
    final inProgressCount = filteredMaintenances
            .where((m) =>
                m['status'] == 'In Progress' || m['status'] == 'In_Progress')
            .length +
        filteredIncidents
            .where((i) =>
                i['status'] == 'Under Investigation' ||
                i['status'] == 'Under_Investigation')
            .length;
    final resolvedCount = filteredMaintenances
            .where((m) => m['status'] == 'Resolved')
            .length +
        filteredIncidents
            .where((i) => i['status'] == 'Resolved')
            .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: Text(
          'STAFF REPORTS & INCIDENTS',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            tooltip: 'Refresh Reports',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ALL'),
                      const SizedBox(width: 6),
                      _buildCountBadge(totalCount, isPrimary: true),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 16),
                      const SizedBox(width: 4),
                      const Text('MAINTENANCE'),
                      const SizedBox(width: 6),
                      _buildCountBadge(filteredMaintenances.length),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16),
                      const SizedBox(width: 4),
                      const Text('INCIDENTS'),
                      const SizedBox(width: 6),
                      _buildCountBadge(filteredIncidents.length, isAlert: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: provider.isReportsLoading
          ? const Center(
              child: SpinKitThreeBounce(
                color: AppTheme.primaryColor,
                size: 32,
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async => _loadData(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // KPI Summary Cards
                  _buildMetricsRow(
                    total: totalCount,
                    pending: pendingCount,
                    inProgress: inProgressCount,
                    resolved: resolvedCount,
                  ),
                  const SizedBox(height: 16),

                  // Filter Bar (Venue dropdown + Status chips)
                  _buildFilterBar(provider.turfs),
                  const SizedBox(height: 16),

                  // Tab Content
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ALL Tab
                        _buildReportsList(
                          items: _filterItems(
                            [
                              ...filteredMaintenances.map((m) =>
                                  {...m, '_reportType': 'maintenance'}),
                              ...filteredIncidents.map(
                                  (i) => {...i, '_reportType': 'incident'}),
                            ]..sort((a, b) {
                                final aDate = DateTime.tryParse(
                                        a['createdAt']?.toString() ?? '') ??
                                    DateTime(1970);
                                final bDate = DateTime.tryParse(
                                        b['createdAt']?.toString() ?? '') ??
                                    DateTime(1970);
                                return bDate.compareTo(aDate);
                              }),
                          ),
                          emptyMessage:
                              'No staff reports found matching filters',
                        ),
                        // MAINTENANCE Tab
                        _buildReportsList(
                          items: _filterItems(filteredMaintenances.map((m) =>
                              {...m, '_reportType': 'maintenance'}).toList()),
                          emptyMessage: 'No maintenance issues reported by staff',
                        ),
                        // INCIDENTS Tab
                        _buildReportsList(
                          items: _filterItems(filteredIncidents.map((i) =>
                              {...i, '_reportType': 'incident'}).toList()),
                          emptyMessage:
                              'No safety incidents reported by staff',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCountBadge(int count,
      {bool isPrimary = false, bool isAlert = false}) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF64748B);
    if (isAlert && count > 0) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFEF4444);
    } else if (isPrimary && count > 0) {
      bg = AppTheme.primaryColor.withValues(alpha: 0.12);
      text = AppTheme.primaryColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }

  Widget _buildMetricsRow({
    required int total,
    required int pending,
    required int inProgress,
    required int resolved,
  }) {
    return Row(
      children: [
        _buildMetricCard('TOTAL', '$total', const Color(0xFF1E293B),
            const Color(0xFFF8FAFC)),
        const SizedBox(width: 8),
        _buildMetricCard('PENDING', '$pending', const Color(0xFFD97706),
            const Color(0xFFFEF3C7)),
        const SizedBox(width: 8),
        _buildMetricCard('ACTIVE', '$inProgress', const Color(0xFF2563EB),
            const Color(0xFFDBEAFE)),
        const SizedBox(width: 8),
        _buildMetricCard('RESOLVED', '$resolved', const Color(0xFF059669),
            const Color(0xFFD1FAE5)),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: textColor.withValues(alpha: 0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<Turf> turfs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Turf Dropdown
          if (turfs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedTurfId,
                  hint: Text(
                    'All Venues',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: Color(0xFF64748B)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Venues (${turfs.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    ...turfs.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(
                          t.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTurfId = val;
                    });
                  },
                ),
              ),
            ),
          if (turfs.isNotEmpty) const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatusChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildStatusChip('PENDING', 'Pending / Reported'),
                const SizedBox(width: 8),
                _buildStatusChip('IN_PROGRESS', 'In Progress / Investigating'),
                const SizedBox(width: 8),
                _buildStatusChip('RESOLVED', 'Resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    if (_selectedStatusFilter == 'ALL') return items;
    return items.where((item) {
      final status = (item['status']?.toString() ?? '').toLowerCase();
      if (_selectedStatusFilter == 'PENDING') {
        return status == 'pending' || status == 'reported';
      }
      if (_selectedStatusFilter == 'IN_PROGRESS') {
        return status == 'in progress' ||
            status == 'in_progress' ||
            status == 'under investigation' ||
            status == 'under_investigation';
      }
      if (_selectedStatusFilter == 'RESOLVED') {
        return status == 'resolved';
      }
      return true;
    }).toList();
  }

  Widget _buildReportsList({
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All ground operations are running smoothly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isIncident = item['_reportType'] == 'incident';
        return _buildReportCard(item, isIncident: isIncident);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> item,
      {required bool isIncident}) {
    final id = (item['_id'] ?? item['id'])?.toString() ?? '';
    final status = (item['status']?.toString() ?? 'Pending').replaceAll('_', ' ');

    // Turf info
    String turfName = 'Venue';
    final turfVal = item['turf'] ?? item['turfId'];
    if (turfVal is Map && turfVal['name'] != null) {
      turfName = turfVal['name'].toString();
    }

    // Reporter info
    String reporterName = 'Staff Member';
    String? reporterPhone;
    String? reporterEmail;
    final repVal = item['reporter'] ?? item['reporterId'];
    if (repVal is Map) {
      if (repVal['name'] != null) reporterName = repVal['name'].toString();
      if (repVal['phone'] != null) reporterPhone = repVal['phone'].toString();
      if (repVal['email'] != null) reporterEmail = repVal['email'].toString();
    }

    // Category / Type
    final category = isIncident
        ? (item['type']?.toString().replaceAll('_', ' ') ?? 'Incident')
        : (item['category']?.toString() ?? 'Maintenance');

    // Severity (for incidents)
    final severity = item['severity']?.toString() ?? 'Low';

    // Description
    final description = item['description']?.toString() ?? 'No description';

    // Images
    final List<dynamic> images = item['images'] is List ? item['images'] : [];

    // Date
    String dateStr = '';
    if (item['createdAt'] != null) {
      final dt = DateTime.tryParse(item['createdAt'].toString());
      if (dt != null) {
        dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
      }
    }

    // Colors
    final Color badgeColor = isIncident
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final Color badgeBg = isIncident
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isIncident
              ? const Color(0xFFFCA5A5).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Badge + Severity + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncident
                          ? Icons.warning_amber_rounded
                          : Icons.engineering_outlined,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isIncident
                          ? 'INCIDENT: ${category.toUpperCase()}'
                          : 'MAINTENANCE: ${category.toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildStatusPill(status),
            ],
          ),

          if (isIncident) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _buildSeverityBadge(severity),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Venue Tag
          Row(
            children: [
              const Icon(Icons.stadium_outlined,
                  size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  turfName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Description box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),

          // Attached Images
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final imgUrl = ApiConstants.getImageUrl(images[idx]?.toString() ?? '');
                  return GestureDetector(
                    onTap: () => _showImagePreviewDialog(context, imgUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFFE2E8F0),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Color(0xFF94A3B8), size: 24),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),

          // Staff Reporter & Action row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: const Icon(Icons.person,
                    size: 16, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reporterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
              // Action Button to update status
              ElevatedButton.icon(
                onPressed: () => _openStatusUpdateSheet(
                  context: context,
                  id: id,
                  currentStatus: status,
                  isIncident: isIncident,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: Text(
                  'STATUS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          if ((reporterPhone != null && reporterPhone.isNotEmpty) ||
              (reporterEmail != null && reporterEmail.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (reporterPhone != null && reporterPhone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        reporterPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                if (reporterEmail != null && reporterEmail.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        reporterEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFFEF3C7);
    Color text = const Color(0xFFD97706);

    final s = status.toLowerCase();
    if (s == 'resolved') {
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF059669);
    } else if (s == 'in progress' || s == 'under investigation') {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color bg = const Color(0xFFFEF3C7);
    Color text = const Color(0xFFB45309);
    final s = severity.toLowerCase();
    if (s == 'high' || s == 'critical') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
    } else if (s == 'medium') {
      bg = const Color(0xFFFFEDD5);
      text = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_gmailerrorred_rounded, size: 12, color: text),
          const SizedBox(width: 3),
          Text(
            'SEVERITY: ${severity.toUpperCase()}',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(32),
                  child: const Text('Failed to load image'),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStatusUpdateSheet({
    required BuildContext context,
    required String id,
    required String currentStatus,
    required bool isIncident,
  }) {
    final List<String> options = isIncident
        ? ['Reported', 'Under Investigation', 'Resolved']
        : ['Pending', 'In Progress', 'Resolved'];

    String chosenStatus = options.firstWhere(
      (opt) => opt.toLowerCase() == currentStatus.toLowerCase(),
      orElse: () => options.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final mediaHeight =
                MediaQuery.maybeOf(context)?.size.height ?? 650;
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: mediaHeight * 0.85),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
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
                      const SizedBox(height: 18),
                      Text(
                        'UPDATE STATUS',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isIncident
                            ? 'Update the investigation status of this safety incident.'
                            : 'Update the resolution progress of this maintenance issue.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status options
                      ...options.map((opt) {
                        final isSelected = chosenStatus == opt;
                        Color accent = AppTheme.primaryColor;
                        if (opt == 'Pending' || opt == 'Reported') {
                          accent = const Color(0xFFD97706);
                        } else if (opt == 'In Progress' ||
                            opt == 'Under Investigation') {
                          accent = const Color(0xFF2563EB);
                        } else if (opt == 'Resolved') {
                          accent = const Color(0xFF059669);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              setSheetState(() {
                                chosenStatus = opt;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected ? accent : const Color(0xFF94A3B8),
                            ),
                            title: Text(
                              opt,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isSelected
                                    ? accent
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          final provider = Provider.of<TurfProvider>(context,
                              listen: false);
                          bool success = false;
                          if (isIncident) {
                            success = await provider.updateIncidentStatus(
                                id, chosenStatus);
                          } else {
                            success = await provider.updateMaintenanceStatus(
                                id, chosenStatus);
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                backgroundColor: success
                                    ? AppTheme.primaryColor
                                    : Colors.redAccent,
                                content: Text(
                                  success
                                      ? 'Status updated to $chosenStatus'
                                      : 'Failed to update status',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'CONFIRM UPDATE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
