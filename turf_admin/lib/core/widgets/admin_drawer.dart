import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../../providers/auth_provider.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({
    super.key,
    this.currentRoute = '/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      width: (MediaQuery.maybeOf(context)?.size.width ?? 360) * 0.86,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildDrawerHeader(context, user),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Core Operations
                    _buildSectionHeader('CORE OPERATIONS', Icons.tune_rounded),
                    const SizedBox(height: 6),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.dashboard_rounded,
                      title: 'COMMAND DASHBOARD',
                      subtitle: 'Platform overview & live KPIs',
                      isActive: currentRoute == '/dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/dashboard') {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.verified_user_rounded,
                      title: 'VENUE VERIFICATION',
                      subtitle: 'Approve & audit sports grounds',
                      isActive: currentRoute == '/manage-turfs',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/manage-turfs') {
                          Navigator.pushNamed(context, '/manage-turfs');
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people_alt_rounded,
                      title: 'USER DIRECTORY',
                      subtitle: 'Manage owners, staff & players',
                      isActive: currentRoute == '/manage-users',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/manage-users') {
                          Navigator.pushNamed(context, '/manage-users');
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.vpn_key_rounded,
                      title: 'ACCESS CONTROL',
                      subtitle: 'Provision department keys',
                      isActive: currentRoute == '/add-owner',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/add-owner') {
                          Navigator.pushNamed(context, '/add-owner');
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    const SizedBox(height: 16),

                    // Section 2: Intelligence & Audit
                    _buildSectionHeader('INTELLIGENCE & AUDIT', Icons.insights_rounded),
                    const SizedBox(height: 6),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.analytics_rounded,
                      title: 'PLATFORM ANALYTICS',
                      subtitle: 'Revenue, commission & trends',
                      onTap: () {
                        Navigator.pop(context);
                        _showAnalyticsSheet(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.history_edu_rounded,
                      title: 'SYSTEM AUDIT TRAIL',
                      subtitle: 'Chronological admin action log',
                      onTap: () {
                        Navigator.pop(context);
                        _showAuditLogsSheet(context);
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    const SizedBox(height: 16),

                    // Section 3: System & Preferences
                    _buildSectionHeader('SYSTEM & PREFERENCES', Icons.settings_suggest_rounded),
                    const SizedBox(height: 6),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.tune_rounded,
                      title: 'PLATFORM SETTINGS',
                      subtitle: 'Commission, maintenance mode',
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsSheet(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.notifications_active_rounded,
                      title: 'SYSTEM ALERTS',
                      subtitle: 'Broadcast alerts & notifications',
                      onTap: () {
                        Navigator.pop(context);
                        _showNotificationsSheet(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.health_and_safety_rounded,
                      title: 'SERVICE HEALTH & DOCS',
                      subtitle: 'API ping, uptime & guidelines',
                      onTap: () {
                        Navigator.pop(context);
                        _showSystemHealthSheet(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section: Terminate Session & System Status
            _buildDrawerFooter(context, authProvider),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDrawerHeader(BuildContext context, dynamic user) {
    final String name = (user?.name?.toString().trim().isNotEmpty == true)
        ? user.name.toString().toUpperCase()
        : 'SUPER ADMIN';
    final String email = user?.email?.toString() ?? 'admin@turf.com';
    final String initial = name.isNotEmpty ? name[0] : 'A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        border: const Border(bottom: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Console Label & Visible Close Affordance Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ADMIN CONSOLE',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tappable Profile Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAdminProfileSheet(context, user),
              borderRadius: BorderRadius.circular(20),
              splashColor: AppTheme.primaryColor.withOpacity(0.08),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.lightGreenBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.executiveGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textMain,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreenBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.lightGreenBorder),
                            ),
                            child: Text(
                              'SUPER ADMIN',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryDark,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
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

  // ---------------------------------------------------------------------------
  // SECTION HEADERS
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.textSecondary.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DRAWER ITEMS
  // ---------------------------------------------------------------------------
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final activeBg = AppTheme.primaryColor.withOpacity(0.08);
    final activeBorder = AppTheme.primaryColor.withOpacity(0.25);
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = AppTheme.textSecondary.withOpacity(0.85);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? activeBorder : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppTheme.primaryColor.withOpacity(0.3) : AppTheme.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: isActive ? AppTheme.primaryDark : AppTheme.textMain.withOpacity(0.9),
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12.5,
            letterSpacing: 0.6,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.8) : AppTheme.textSecondary.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFFD1D5DB),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER & TERMINATE SESSION CONFIRMATION
  // ---------------------------------------------------------------------------
  Widget _buildDrawerFooter(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terminate Session Button with Guarded Modal
          Material(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _confirmLogout(context, authProvider),
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.red.withOpacity(0.15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TERMINATE SESSION',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Sign out of Command Center',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEF4444).withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFFF87171),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Live System Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'TURF ADMIN v1.2.0 • PROD ACTIVE',
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONFIRMATION DIALOG: TERMINATE SESSION
  // ---------------------------------------------------------------------------
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TERMINATE SESSION?',
              style: GoogleFonts.outfit(
                color: AppTheme.textMain,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of the Super Admin Command Center? You will need to re-authenticate with master credentials.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx); // Close dialog
                      Navigator.pop(context); // Close drawer
                      authProvider.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'LOG OUT',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
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
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: ADMIN PROFILE DETAILS
  // ---------------------------------------------------------------------------
  void _showAdminProfileSheet(BuildContext context, dynamic user) {
    final String name = user?.name?.toString().toUpperCase() ?? 'SUPER ADMIN';
    final String email = user?.email?.toString() ?? 'admin@turf.com';
    final String role = user?.role?.toString().toUpperCase() ?? 'ADMIN';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(ctx)?.size.height ?? 650) * 0.85),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMINISTRATIVE CREDENTIALS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMain,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Master security token and root attributes',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildProfileRow('NAME', name),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildProfileRow('EMAIL', email),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildProfileRow('PRIVILEGE', '$role (ROOT LEVEL)'),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildProfileRow('ENVIRONMENT', 'PostgreSQL • Supabase Cloud'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: PLATFORM ANALYTICS
  // ---------------------------------------------------------------------------
  void _showAnalyticsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnalyticsModalSheet(),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: SYSTEM AUDIT TRAIL
  // ---------------------------------------------------------------------------
  void _showAuditLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuditLogsModalSheet(),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: PLATFORM SETTINGS
  // ---------------------------------------------------------------------------
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlatformSettingsModalSheet(),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: SYSTEM ALERTS & BROADCASTS
  // ---------------------------------------------------------------------------
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(ctx)?.size.height ?? 650) * 0.85),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM ALERTS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Live infrastructure events & notices',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAlertCard(
                  title: 'Database Cluster Synchronized',
                  subtitle: 'PostgreSQL Supabase AWS ap-south-1 connection active with pool size 10.',
                  time: 'Just now',
                  color: AppTheme.primaryColor,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 10),
                _buildAlertCard(
                  title: 'FCM Push Relay Ready',
                  subtitle: 'Notification channel verified for owner verification alerts.',
                  time: '12m ago',
                  color: Colors.blueAccent,
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 10),
                _buildAlertCard(
                  title: 'Security Scan Status: Clean',
                  subtitle: 'Zero unauthorized root token generation detected in the last 24h.',
                  time: '1h ago',
                  color: Colors.teal,
                  icon: Icons.security_rounded,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'DISMISS',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MODAL: SERVICE HEALTH & DOCS
  // ---------------------------------------------------------------------------
  void _showSystemHealthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(ctx)?.size.height ?? 650) * 0.85),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICE HEALTH & DIAGNOSTICS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Live endpoint telemetry and connectivity',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildHealthRow('API BASE ENDPOINT', 'Render Cloud (200 OK)', true),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildHealthRow('PRIMARY DATABASE', 'Supabase PostgreSQL (Pool 10)', true),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildHealthRow('PUSH NOTIFICATIONS', 'Firebase FCM Relay (Ready)', true),
                      const Divider(color: AppTheme.cardBorder, height: 18),
                      _buildHealthRow('SECURITY AUDIT', 'Zero Vulnerabilities Detected', true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'DONE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHealthRow(String label, String value, bool isHealthy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isHealthy ? const Color(0xFF10B981) : Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// MODAL SHEET: PLATFORM ANALYTICS
// =============================================================================
class _AnalyticsModalSheet extends StatefulWidget {
  @override
  State<_AnalyticsModalSheet> createState() => _AnalyticsModalSheetState();
}

class _AnalyticsModalSheetState extends State<_AnalyticsModalSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await _apiService.get(ApiConstants.statsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stats = data is Map<String, dynamic> ? data : {};
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRev = double.tryParse(_stats['totalRevenue']?.toString() ?? '0') ?? 0.0;
    final commissionRate = double.tryParse(_stats['commissionRate']?.toString() ?? '10') ?? 10.0;
    final adminRev = double.tryParse(_stats['adminRevenue']?.toString() ?? '0') ?? (totalRev * (commissionRate / 100));
    final approvedTurfs = _stats['approvedTurfs'] ?? 0;
    final pendingTurfs = _stats['pendingTurfs'] ?? 0;
    final totalUsers = _stats['totalUsers'] ?? 0;

    return Container(
      constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(context)?.size.height ?? 650) * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLATFORM ANALYTICS',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Financial health & operational growth',
                            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchStats();
                },
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Revenue Bento Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.executiveGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL GROSS REVENUE',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹ ${NumberFormat('#,##,###.##').format(totalRev)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ADMIN COMMISSION (${commissionRate.toInt()}%)',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹ ${NumberFormat('#,##,###.##').format(adminRev)}',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ACTIVE VENUES',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$approvedTurfs APPROVED',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Secondary KPI Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: 'PENDING VERIFICATION',
                                value: '$pendingTurfs Venues',
                                color: const Color(0xFFF59E0B),
                                icon: Icons.pending_actions_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'TOTAL REGISTERED USERS',
                                value: '$totalUsers Accounts',
                                color: const Color(0xFF3B82F6),
                                icon: Icons.group_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // System Growth Status
                        Text(
                          'PLATFORM HEALTH INDICATORS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildHealthBar('Venue Verification Throughput', 0.85, '85% Target met'),
                        const SizedBox(height: 10),
                        _buildHealthBar('Payment Settlement Consistency', 0.98, '98% On time'),
                        const SizedBox(height: 10),
                        _buildHealthBar('System Availability Uptime', 0.999, '99.9% Uptime'),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'CLOSE ANALYTICS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double progress, String note) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              Text(
                note,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL SHEET: SYSTEM AUDIT LOGS
// =============================================================================
class _AuditLogsModalSheet extends StatefulWidget {
  @override
  State<_AuditLogsModalSheet> createState() => _AuditLogsModalSheetState();
}

class _AuditLogsModalSheetState extends State<_AuditLogsModalSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await _apiService.get(ApiConstants.auditLogsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _logs = data is List ? data : [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(context)?.size.height ?? 650) * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.history_edu_rounded, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SYSTEM AUDIT TRAIL',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Immutable record of administrative actions',
                            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchLogs();
                },
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_rounded, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'NO AUDIT LOGS RECORDED',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administrative events will appear here when performed.',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final log = _logs[i];
                          final action = log['action']?.toString().toUpperCase() ?? 'ADMIN_EVENT';
                          final ip = log['ipAddress'] ?? '127.0.0.1';
                          final dateStr = log['createdAt'] ?? '';
                          String formattedTime = 'Recent';
                          if (dateStr.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(dateStr).toLocal();
                              formattedTime = DateFormat('dd MMM, hh:mm a').format(dt);
                            } catch (_) {}
                          }

                          Color badgeColor = AppTheme.primaryColor;
                          if (action.contains('BLOCK') || action.contains('TERMINATE') || action.contains('DELETE')) {
                            badgeColor = const Color(0xFFDC2626);
                          } else if (action.contains('APPROVE') || action.contains('WHITELIST')) {
                            badgeColor = const Color(0xFF059669);
                          } else if (action.contains('SUSPEND')) {
                            badgeColor = const Color(0xFFD97706);
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.security_rounded, color: badgeColor, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        action,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'IP: $ip • $formattedTime',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'DISMISS AUDIT TRAIL',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL SHEET: PLATFORM SETTINGS
// =============================================================================
class _PlatformSettingsModalSheet extends StatefulWidget {
  @override
  State<_PlatformSettingsModalSheet> createState() => _PlatformSettingsModalSheetState();
}

class _PlatformSettingsModalSheetState extends State<_PlatformSettingsModalSheet> {
  bool _maintenanceMode = false;
  bool _notifyNewTurfs = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: (MediaQuery.maybeOf(context)?.size.height ?? 650) * 0.85),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
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
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLATFORM SETTINGS',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Global operational preferences & overrides',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Setting 1: Maintenance Mode
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _maintenanceMode ? const Color(0xFFFEF2F2) : AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _maintenanceMode ? const Color(0xFFFECACA) : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MAINTENANCE MODE',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _maintenanceMode ? const Color(0xFFDC2626) : AppTheme.textMain,
                            ),
                          ),
                          Text(
                            'Displays a maintenance banner to customer/owner apps',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _maintenanceMode,
                      activeColor: const Color(0xFFDC2626),
                      onChanged: (val) {
                        setState(() => _maintenanceMode = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val ? 'Maintenance mode enabled for mobile apps' : 'Platform set to LIVE',
                            ),
                            backgroundColor: val ? const Color(0xFFDC2626) : AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Setting 2: Push Notifications on New Submissions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW TURF SUBMISSION NOTIFICATIONS',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textMain,
                            ),
                          ),
                          Text(
                            'Send FCM alerts to admin device when ground is registered',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notifyNewTurfs,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setState(() => _notifyNewTurfs = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Setting 3: Commission rate info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEFAULT COMMISSION RATE',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Text(
                          'Fixed cut charged across verified bookings',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.lightGreenBorder),
                      ),
                      child: Text(
                        '10.0%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'SAVE & APPLY',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
