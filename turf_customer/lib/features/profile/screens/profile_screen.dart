import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/booking_provider.dart';
import 'profile_bookings_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../../core/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final user = auth.user;

    final upcomingCount = bookingProvider.myBookings
        .where((b) => b['status'] == 'confirmed' || b['status'] == 'checked-in')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context, auth),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Avatar with Animated Pencil Badge
                  _buildAvatarSection(context, user),
                  const SizedBox(height: 14),

                  // Name and Email with enhanced typography contrast
                  Text(
                    user?['name'] ?? 'Athlete',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?['email'] ?? 'customer@turf.com',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section 1: Account
                  _buildSectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),

                  _buildActionCard(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    title: 'Edit Profile',
                    subtitle: 'Personal details & photo',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildActionCard(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF047857),
                    title: 'My Bookings',
                    subtitle: 'Slots, history & receipts',
                    badgeText: upcomingCount > 0 ? '$upcomingCount upcoming' : null,
                    isHighlighted: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileBookingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Preferences & Support
                  _buildSectionLabel('PREFERENCES & SUPPORT'),
                  const SizedBox(height: 8),

                  _buildActionCard(
                    context: context,
                    icon: Icons.tune_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF475569),
                    title: 'Settings',
                    subtitle: 'Theme, language & terms',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildActionCard(
                    context: context,
                    icon: Icons.support_agent_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Help & Support',
                    subtitle: 'FAQs & instant assistance',
                    onTap: () => _showHelpBottomSheet(context),
                  ),

                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => _confirmLogout(context, auth),
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 18),
                      label: Text(
                        'LOG OUT',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFE11D48),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFFECDD3), width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, Map<String, dynamic>? user) {
    final profileImageUrl = ApiConstants.getFullUrl(user?['profileImage']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFECFDF5),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18047857),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40F59E0B),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFECFDF5),
      child: Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          size: 46,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withOpacity(0.08),
        highlightColor: iconColor.withOpacity(0.04),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              width: isHighlighted ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isHighlighted ? const Color(0x0C059669) : Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[900]!, Colors.green[700]!],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 48), // Balance for logout icon
                Expanded(
                  child: Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmLogout(context, auth),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your sports profile and activity',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out of your account?', style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help & Support',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Need assistance with your booking or profile?',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                    child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669), size: 20),
                  ),
                  title: Text('Call Turf Support Desk', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('+91 98765 43210 (9 AM - 10 PM)', style: GoogleFonts.outfit(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFFF8FAFC),
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  title: Text('Email Support', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('support@turfbooking.com', style: GoogleFonts.outfit(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFFF8FAFC),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
