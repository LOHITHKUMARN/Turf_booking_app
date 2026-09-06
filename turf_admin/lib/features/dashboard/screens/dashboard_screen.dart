import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/admin_drawer.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'pendingTurfs': 0,
    'approvedTurfs': 0,
    'totalRevenue': 0,
    'adminRevenue': 0,
    'commissionRate': 10,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await _apiService.get(ApiConstants.statsUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _stats = decoded;
            _isLoadingStats = false;
          });
          return;
        }
      }
      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      drawer: const AdminDrawer(currentRoute: '/dashboard'),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildExecutiveHero(user?.name ?? 'Admin'),
                  const SizedBox(height: 32),
                  _buildStatsGrid(),
                  const SizedBox(height: 40),
                  _buildQuickLinks(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.headerGreen,
      surfaceTintColor: AppTheme.headerGreen,
      iconTheme: const IconThemeData(color: Colors.white, size: 20),
      centerTitle: true,
      title: Text(
        'COMMAND CENTER',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() => _isLoadingStats = true);
            _fetchStats();
          },
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildExecutiveHero(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.executiveGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
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
              Text(
                "SYSTEM OVERVIEW",
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      "LIVE",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Welcome back,\n$name".toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoadingStats) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
      ));
    }

    final totalRev = double.tryParse(_stats['totalRevenue']?.toString() ?? '0') ?? 0.0;
    final adminRev = double.tryParse(_stats['adminRevenue']?.toString() ?? '0') ?? (totalRev * 0.10);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard('PENDING TURFS', (_stats['pendingTurfs'] ?? 0).toString(), Icons.stadium_rounded),
              const SizedBox(width: 16),
              _buildStatCard('APPROVED TURFS', (_stats['approvedTurfs'] ?? 0).toString(), Icons.check_circle_outline_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard('TOTAL USERS', (_stats['totalUsers'] ?? 0).toString(), Icons.people_alt_rounded),
              const SizedBox(width: 16),
              _buildStatCard('COMMISSION %', '${_stats['commissionRate'] ?? 10}%', Icons.analytics_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard('TOTAL REVENUE', '₹ ${totalRev.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined),
              const SizedBox(width: 16),
              _buildStatCard('ADMIN REVENUE', '₹ ${adminRev.toStringAsFixed(2)}', Icons.trending_up_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.lightGreenBg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.lightGreenBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.lightGreenBorder),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: AppTheme.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDark.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("OPERATIONAL CONTROL"),
        const SizedBox(height: 20),
        _buildLinkItem(Icons.verified_user_rounded, "TURF VERIFICATION", "Review and approve partner venues", '/manage-turfs'),
        const SizedBox(height: 12),
        _buildLinkItem(Icons.group_work_rounded, "USER MANAGEMENT", "Monitor activity across the platform", '/manage-users'),
        const SizedBox(height: 12),
        _buildLinkItem(Icons.person_add_alt_1_rounded, "ONBOARD DEPARTMENTS", "Provision new owner access keys", '/add-owner'),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 12, height: 2, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppTheme.textMain.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(IconData icon, String title, String subtitle, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.lightGreenBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGreenBorder),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

