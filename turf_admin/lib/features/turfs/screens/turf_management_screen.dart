import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:convert';

class TurfManagementScreen extends StatefulWidget {
  const TurfManagementScreen({super.key});

  @override
  State<TurfManagementScreen> createState() => _TurfManagementScreenState();
}

class _TurfManagementScreenState extends State<TurfManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _turfs = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'suspended'
  final Set<String> _expandedTurfIds = {};

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTurfs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.turfsUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _turfs = decoded;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading venues: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String turfId, String status) async {
    try {
      final response = await _apiService.post(
        ApiConstants.turfStatusUrl,
        {'turfId': turfId, 'status': status},
      );
      if (response.statusCode == 200) {
        await _fetchTurfs();
        if (mounted) {
          final isApproved = status == 'approved';
          _showSnackBar(
            'VENUE ${status.toUpperCase()} SUCCESSFULLY',
            isApproved ? AppTheme.primaryColor : Colors.redAccent,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to update status', Colors.redAccent);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Network error: $e', Colors.redAccent);
      }
    }
  }

  void _confirmSuspension(String turfId, String venueName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SUSPEND VENUE',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.textMain,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to suspend "$venueName"?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This venue will be immediately hidden from customer apps and disabled for all booking operations.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(turfId, 'suspended');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'SUSPEND',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  List<dynamic> get _filteredTurfs {
    final query = _searchController.text.trim().toLowerCase();
    return _turfs.where((turf) {
      final name = (turf['name'] ?? '').toString().toLowerCase();
      final city = (turf['location']?['city'] ?? turf['city'] ?? '').toString().toLowerCase();
      final area = (turf['location']?['area'] ?? turf['area'] ?? '').toString().toLowerCase();
      final sports = (turf['sports'] is List ? (turf['sports'] as List).join(' ') : '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          city.contains(query) ||
          area.contains(query) ||
          sports.contains(query);

      final status = (turf['status'] ?? 'pending').toString().toLowerCase();
      final matchesFilter = _selectedFilter == 'all' || status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _countForStatus(String status) {
    return _turfs.where((t) => (t['status'] ?? 'pending').toString().toLowerCase() == status).length;
  }

  IconData _getSportIcon(List<dynamic>? sports) {
    if (sports == null || sports.isEmpty) return Icons.stadium_rounded;
    final joined = sports.join(' ').toLowerCase();
    if (joined.contains('cricket') && !joined.contains('football')) {
      return Icons.sports_cricket_rounded;
    }
    if (joined.contains('football') && !joined.contains('cricket')) {
      return Icons.sports_soccer_rounded;
    }
    if (joined.contains('tennis') || joined.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    }
    if (joined.contains('basketball')) {
      return Icons.sports_basketball_rounded;
    }
    return Icons.stadium_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTurfs;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          'VENUE VERIFICATION',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.headerGreen,
        surfaceTintColor: AppTheme.headerGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 18),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _fetchTurfs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTurfs,
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final turf = filtered[index];
                            final turfId = (turf['_id'] ?? turf['id'] ?? index.toString()).toString();
                            final isExpanded = _expandedTurfIds.contains(turfId);
                            return _buildRedesignedTurfCard(turf, turfId, isExpanded);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    final allCount = _turfs.length;
    final pendingCount = _countForStatus('pending');
    final approvedCount = _countForStatus('approved');
    final suspendedCount = _countForStatus('suspended');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Search Input Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Search by venue name, city, or sport...',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('ALL ($allCount)', 'all', AppTheme.primaryDark),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING ($pendingCount)', 'pending', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildFilterChip('APPROVED ($approvedCount)', 'approved', AppTheme.primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('SUSPENDED ($suspendedCount)', 'suspended', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.8,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty || _selectedFilter != 'all';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.stadium_rounded,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'NO MATCHING VENUES' : 'NO VENUES REGISTERED',
              style: GoogleFonts.outfit(
                color: AppTheme.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'No results matched your search or status filter. Try clearing filters.'
                  : 'All systems are currently up to date.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (isSearching) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedFilter = 'all';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'RESET FILTERS',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRedesignedTurfCard(dynamic turf, String turfId, bool isExpanded) {
    final status = (turf['status'] ?? 'pending').toString().toLowerCase();
    final name = (turf['name'] ?? 'Unnamed Venue').toString();
    final area = (turf['location']?['area'] ?? turf['area'] ?? '').toString();
    final city = (turf['location']?['city'] ?? turf['city'] ?? '').toString();
    final locationText = [area, city].where((s) => s.isNotEmpty).join(', ');

    final sportsList = (turf['sports'] is List) ? (turf['sports'] as List) : [];
    final groundsList = (turf['grounds'] is List) ? (turf['grounds'] as List) : [];
    final turfType = (turf['turfType'] ?? 'both').toString().toUpperCase();
    final images = (turf['images'] is List) ? (turf['images'] as List) : [];
    final owner = turf['owner'] as Map<String, dynamic>?;

    final sportIcon = _getSportIcon(sportsList);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? AppTheme.primaryColor.withValues(alpha: 0.35) : AppTheme.cardBorder,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          // Collapsed / Header Tap Bar
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTurfIds.remove(turfId);
                } else {
                  _expandedTurfIds.add(turfId);
                }
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sport Leading Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.lightGreenBorder),
                    ),
                    child: Icon(sportIcon, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Name and Location (generous space with wrapping)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textMain,
                            fontSize: 15,
                            letterSpacing: 0.4,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.textSecondary.withValues(alpha: 0.6),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText.isNotEmpty ? locationText.toUpperCase() : 'LOCATION NOT SPECIFIED',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Trailing Status Badge & Chevron Icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildDistinctStatusBadge(status),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details Body
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bento Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildBentoCard(
                          label: 'VENUE TYPE',
                          value: sportsList.isNotEmpty
                              ? sportsList.join(' • ').toUpperCase()
                              : 'GENERAL SPORTS',
                          icon: Icons.sports_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBentoCard(
                          label: 'GROUNDS & FACILITY',
                          value: '${groundsList.length} UNITS • $turfType',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                    ],
                  ),

                  // Owner Information Row (if available)
                  if (owner != null && owner['name'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OWNER / MANAGER',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF475569),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '${owner['name']}  •  ${owner['phone'] ?? owner['email'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Venue Photos / Documents Strip (if available)
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'VENUE PHOTOS & PROOF',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF475569),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final imgUrl = ApiConstants.getFullUrl(images[i].toString());
                          return GestureDetector(
                            onTap: () => _viewFullImage(imgUrl, name),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imgUrl,
                                width: 72,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 64,
                                  color: AppTheme.bgColor,
                                  child: const Icon(Icons.image_not_supported_rounded, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Dynamic Action Buttons
                  _buildActionButtons(turfId, name, status),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewFullImage(String imgUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Unable to load photo', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDistinctStatusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    IconData icon;
    String label = status.toUpperCase();

    switch (status) {
      case 'approved':
        textColor = const Color(0xFF047857); // Deep emerald
        bgColor = const Color(0xFFECFDF5); // Soft emerald tint
        borderColor = const Color(0xFFA7F3D0);
        icon = Icons.check_circle_rounded;
        break;
      case 'suspended':
        textColor = const Color(0xFFB91C1C); // Deep red
        bgColor = const Color(0xFFFEF2F2); // Soft red tint
        borderColor = const Color(0xFFFECACA);
        icon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        textColor = const Color(0xFFB45309); // Deep amber
        bgColor = const Color(0xFFFFFBEB); // Soft amber tint
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.schedule_rounded;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF475569), // High contrast slate
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF0F172A), // Dark charcoal
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String turfId, String venueName, String status) {
    if (status == 'approved') {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE & VERIFIED',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: const Color(0xFF047857),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _confirmSuspension(turfId, venueName),
                icon: const Icon(Icons.block_rounded, size: 16),
                label: Text(
                  'SUSPEND',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'suspended') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(turfId, 'approved'),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'RE-AUTHORIZE',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.do_not_disturb_on_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'SUSPENDED',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Colors.redAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Pending status: Authorize vs Reject
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(turfId, 'approved'),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(
                'AUTHORIZE',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSuspension(turfId, venueName),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(
                'REJECT',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
