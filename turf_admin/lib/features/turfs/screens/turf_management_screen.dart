import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:convert';

class TurfManagementScreen extends StatefulWidget {
  const TurfManagementScreen({super.key});

  @override
  _TurfManagementScreenState createState() => _TurfManagementScreenState();
}

class _TurfManagementScreenState extends State<TurfManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _turfs = [];

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
  }

  Future<void> _fetchTurfs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.turfsUrl);
      if (response.statusCode == 200) {
        setState(() {
          _turfs = jsonDecode(response.body);
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String turfId, String status) async {
    try {
      final response = await _apiService.post(
        ApiConstants.turfStatusUrl,
        {'turfId': turfId, 'status': status},
      );
      if (response.statusCode == 200) {
        _fetchTurfs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('STATUS: ${status.toUpperCase()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('VENUE VERIFICATION', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: Colors.white)),
        elevation: 0,
        backgroundColor: AppTheme.headerGreen,
        surfaceTintColor: AppTheme.headerGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 18),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTurfs,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
            : _turfs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    itemCount: _turfs.length,
                    itemBuilder: (context, index) {
                      final turf = _turfs[index];
                      return _buildPremiumTurfCard(turf);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor, 
              shape: BoxShape.circle, 
              boxShadow: AppTheme.softShadow
            ),
            child: const Icon(Icons.stadium_rounded, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "NO PENDING REQUESTS",
            style: GoogleFonts.outfit(color: AppTheme.textMain, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            "Systems are currently up to date.",
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTurfCard(dynamic turf) {
    final status = turf['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          leading: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports_soccer_rounded, color: AppTheme.primaryColor, size: 24),
          ),
          title: Text(
            turf['name'].toUpperCase(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textMain, fontSize: 15, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${turf['location']?['area'] ?? ''}, ${turf['location']?['city'] ?? ''}'.toUpperCase(),
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          trailing: _buildStatusBadge(status, statusColor),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildBentoInfo('VENUE TYPE', (turf['sports'] as List).join(' • ').toUpperCase())),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBentoInfo('TOTAL GROUNDS', '${turf['grounds']?.length ?? 0} UNITS')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'AUTHORIZE', 
                          AppTheme.primaryColor, 
                          status == 'approved' ? null : () => _updateStatus(turf['_id'], 'approved'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'SUSPEND', 
                          Colors.redAccent, 
                          status == 'suspended' ? null : () => _updateStatus(turf['_id'], 'suspended'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBentoInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(color: AppTheme.textMain, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback? onTap) {
    final isDisabled = onTap == null;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppTheme.bgColor : color,
          foregroundColor: isDisabled ? AppTheme.textSecondary.withOpacity(0.3) : Colors.white,
          elevation: isDisabled ? 0 : 4,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppTheme.primaryColor;
      case 'suspended': return Colors.redAccent;
      case 'pending': return Colors.orangeAccent;
      default: return AppTheme.textSecondary;
    }
  }
}
