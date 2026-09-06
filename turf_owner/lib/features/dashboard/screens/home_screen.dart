import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/turf_provider.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final turfProvider = Provider.of<TurfProvider>(context, listen: false);
      turfProvider.fetchMyTurfs();
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final stats = await Provider.of<TurfProvider>(context, listen: false).fetchStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: Text('DASHBOARD', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: const Color(0xFF00A86B))),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF00A86B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context, owner),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumHeader(owner),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('QUICK ACTIONS'),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 32),
                    if (_stats?['advanced']?['insights'] != null) ...[
                      _buildSectionHeader('AI INSIGHTS'),
                      const SizedBox(height: 16),
                      _buildInsightsSection(_stats!['advanced']['insights']),
                      const SizedBox(height: 32),
                    ],
                    _buildSectionHeader('TODAY\'S PERFORMANCE'),
                    const SizedBox(height: 16),
                    _buildTodayOverviewCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF64748B),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildActionItem(Icons.event_note_outlined, 'Bookings', () {
          Navigator.pushNamed(context, '/bookings');
        }),
        _buildActionItem(Icons.block_outlined, 'Block', () {
          Navigator.pushNamed(context, '/block-slots');
        }),
        _buildActionItem(Icons.people_outline, 'Staff', () {
          Navigator.pushNamed(context, '/staff-list');
        }),
        _buildActionItem(Icons.report_problem_outlined, 'Reports', () {
          Navigator.pushNamed(context, '/staff-reports');
        }),
        _buildActionItem(Icons.badge_outlined, 'Attendance', () {
          Navigator.pushNamed(context, '/staff-attendance');
        }),
        _buildActionItem(Icons.campaign_outlined, "Announcements", () {
          Navigator.pushNamed(context, '/announcements');
        }),
        _buildActionItem(Icons.payments_outlined, 'Payouts', () {
          Navigator.pushNamed(context, '/payouts');
        }),
        _buildActionItem(Icons.emoji_events_outlined, 'Tournaments', () {
          Navigator.pushNamed(context, '/tournaments');
        }),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.05)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: const Color(0xFF00A86B), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(List<dynamic> insights) {
    return Column(
      children: insights.take(2).map((insight) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00A86B), size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                insight.toString(),
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTodayOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildOverviewRow('DAILY REVENUE', 'Rs. ${_stats?['todayRevenue'] ?? 0}', Icons.trending_up_rounded, const Color(0xFF00A86B)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFFF1F5F9), thickness: 1)),
          _buildOverviewRow('ACTIVE BOOKINGS', '${_stats?['todayBookings'] ?? 0}', Icons.calendar_today_rounded, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildPremiumHeader(owner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK,',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF00A86B), fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owner?.name?.toUpperCase() ?? "OWNER",
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.1), width: 4),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFF8FBF9),
                  child: Icon(Icons.person_outline_rounded, color: Color(0xFF00A86B), size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TOTAL REVENUE',
            'Rs. ${_stats?['totalRevenue'] ?? 0}',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF00A86B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'BOOKINGS',
            '${_stats?['totalBookings'] ?? 0}',
            Icons.calendar_month_rounded,
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, owner) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, left: 24, bottom: 24, right: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: const Color(0xFF00A86B).withOpacity(0.05))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.1)), shape: BoxShape.circle),
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundColor: Color(0xFFF8FBF9),
                            child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF00A86B)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          owner?.name?.toUpperCase() ?? 'OWNER',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: 1),
                        ),
                        Text(
                          owner?.email?.toLowerCase() ?? '',
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDrawerItem(Icons.dashboard_rounded, 'DASHBOARD', () => Navigator.pop(context), isActive: true),
                  _buildDrawerItem(Icons.analytics_rounded, 'ANALYTICS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analytics');
                  }),
                  _buildDrawerItem(Icons.stadium_rounded, 'VENUES', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/manage-venues');
                  }),
                  _buildDrawerItem(Icons.event_note_rounded, 'BOOKINGS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/bookings');
                  }),
                  _buildDrawerItem(Icons.people_alt_rounded, 'STAFF', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/staff-list');
                  }),
                  _buildDrawerItem(Icons.report_problem_rounded, 'STAFF REPORTS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/staff-reports');
                  }),
                  _buildDrawerItem(Icons.badge_rounded, 'ATTENDANCE', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/staff-attendance');
                  }),
                  _buildDrawerItem(Icons.payments_rounded, 'PAYOUTS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/payouts');
                  }),
                  _buildDrawerItem(Icons.emoji_events_rounded, 'TOURNAMENTS', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/tournaments');
                  }),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            _buildDrawerItem(Icons.logout_rounded, 'LOGOUT', () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            }, color: Colors.redAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isActive = false, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (isActive ? AppTheme.primaryColor : const Color(0xFF64748B)), size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: color ?? (isActive ? AppTheme.primaryColor : const Color(0xFF64748B)),
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
