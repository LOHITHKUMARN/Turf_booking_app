import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'profile_bookings_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../../core/constants/api_constants.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, auth),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen())),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: () {
                      final img = ApiConstants.getFullUrl(user?['profileImage']);
                      return img.isNotEmpty ? NetworkImage(img) : null;
                    }(),
                    child: user?['profileImage'] == null || user!['profileImage'].toString().isEmpty
                        ? const Icon(Icons.person_outline_rounded, size: 55, color: Colors.green)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Icon(Icons.edit, size: 16, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?['name'] ?? 'User Name',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user?['email'] ?? 'user@email.com',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            
            _buildActionItem(
              context: context,
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen())),
            ),
            _buildActionItem(
              context: context,
              icon: Icons.calendar_today_rounded,
              title: 'My Bookings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileBookingsScreen())),
            ),
            _buildActionItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())),
            ),
            _buildActionItem(
              context: context,
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {},
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: Text('LOGOUT', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required BuildContext context, required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light 
                ? Colors.grey[400]! 
                : Theme.of(context).dividerColor.withOpacity(0.8),
              width: 1.2
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.green[800], size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
                  onPressed: () => auth.logout(),
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
}
