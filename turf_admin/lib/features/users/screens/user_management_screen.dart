import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:convert';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _users = [];
  String _selectedRoleFilter = 'all'; // 'all', 'staff', 'owner', 'customer', 'admin'

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.usersUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _users = decoded;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading directory: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiService.post(
        ApiConstants.userStatusUrl,
        {'userId': userId, 'status': status},
      );
      if (response.statusCode == 200) {
        await _fetchUsers();
        if (mounted) {
          final isActivated = status == 'active';
          _showSnackBar(
            isActivated ? 'USER ACCESS RESTORED' : 'USER ACCESS TERMINATED',
            isActivated ? AppTheme.primaryColor : const Color(0xFFD97706),
          );
        }
      } else {
        if (mounted) {
          _showSnackBar('Status update failed', Colors.redAccent);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Network error: $e', Colors.redAccent);
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.delete('${ApiConstants.deleteUserUrl}/$userId');
      if (response.statusCode == 200) {
        await _fetchUsers();
        if (mounted) {
          _showSnackBar('USER DELETED PERMANENTLY', Colors.black87);
        }
      } else {
        if (mounted) {
          _showSnackBar('Deletion failed', Colors.redAccent);
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.redAccent);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation(String userId, String name, String email) {
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
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'DELETE ACCOUNT?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: const Color(0xFF991B1B),
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
              'Are you sure you want to delete "$name" ($email)?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is irreversible and permanently removes all user profiles, tokens, and records.',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF991B1B), height: 1.3),
                    ),
                  ),
                ],
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
              _deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'DELETE FOREVER',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserActionSheet(dynamic user) {
    final userId = (user['_id'] ?? user['id'] ?? '').toString();
    final name = (user['name'] ?? 'Unnamed User').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final role = (user['role'] ?? 'customer').toString().toLowerCase();
    final status = (user['status'] ?? 'active').toString().toLowerCase();
    final isActive = status == 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // User Header Info in Sheet
                Row(
                  children: [
                    _buildRoleAvatar(name, role, size: 52),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.textMain,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (phone.isNotEmpty)
                            Text(
                              phone,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Badges Row
                Row(
                  children: [
                    _buildRoleBadge(role),
                    const SizedBox(width: 10),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 16),

                // Actions Section
                Text(
                  'MANAGE USER ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF475569),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Whitelist / Activate (if blocked)
                if (!isActive)
                  _buildSheetActionTile(
                    icon: Icons.check_circle_rounded,
                    title: 'WHITELIST / ACTIVATE USER',
                    subtitle: 'Restore full booking and platform privileges',
                    color: AppTheme.primaryColor,
                    bgColor: const Color(0xFFECFDF5),
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateUserStatus(userId, 'active');
                    },
                  ),

                // 2. Terminate / Suspend (if active)
                if (isActive)
                  _buildSheetActionTile(
                    icon: Icons.block_rounded,
                    title: 'TERMINATE ACCESS',
                    subtitle: 'Temporarily suspend account and disable login',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateUserStatus(userId, 'blocked');
                    },
                  ),

                const SizedBox(height: 10),

                // 3. Delete Account (Permanently)
                _buildSheetActionTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'DELETE ACCOUNT PERMANENTLY',
                  subtitle: 'Irreversible action. Wipes out credentials & history',
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmation(userId, name, email);
                  },
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
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

  List<dynamic> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? 'customer').toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          role.contains(query);

      final matchesFilter = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  int _countForRole(String role) {
    return _users.where((u) => (u['role'] ?? 'customer').toString().toLowerCase() == role).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          'USER DIRECTORY',
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
            onPressed: _fetchUsers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            return _buildRedesignedUserCard(user);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    final allCount = _users.length;
    final staffCount = _countForRole('staff');
    final ownerCount = _countForRole('owner');
    final customerCount = _countForRole('customer');
    final adminCount = _countForRole('admin');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Search Input
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
                hintText: 'Search by name, email, phone, or role...',
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

          // Horizontal Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildRoleFilterChip('ALL ($allCount)', 'all', AppTheme.primaryDark),
                const SizedBox(width: 8),
                _buildRoleFilterChip('STAFF ($staffCount)', 'staff', const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildRoleFilterChip('OWNERS ($ownerCount)', 'owner', const Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                _buildRoleFilterChip('CUSTOMERS ($customerCount)', 'customer', const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                _buildRoleFilterChip('ADMINS ($adminCount)', 'admin', const Color(0xFFD97706)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String roleValue, Color color) {
    final isSelected = _selectedRoleFilter == roleValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = roleValue),
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
    final isSearching = _searchController.text.isNotEmpty || _selectedRoleFilter != 'all';
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
                isSearching ? Icons.person_search_rounded : Icons.supervised_user_circle_rounded,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'NO MATCHING USERS' : 'NO RECORDS FOUND',
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
                  ? 'No users match your search or filter. Try clearing filters.'
                  : 'Try pulling down to refresh sync records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (isSearching) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedRoleFilter = 'all';
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

  Widget _buildRedesignedUserCard(dynamic user) {
    final status = (user['status'] ?? 'active').toString().toLowerCase();
    final role = (user['role'] ?? 'customer').toString().toLowerCase();
    final name = (user['name'] ?? 'Unnamed User').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showUserActionSheet(user),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Role-Coded Avatar with Initials
              _buildRoleAvatar(name, role, size: 48),
              const SizedBox(width: 14),

              // User Info (Full name without truncation, email & phone)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Role Tag in one clean wrap
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textMain,
                              fontSize: 14.5,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(role),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Email Address
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

                    // Phone & Status Row
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusPill(status),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.phone_rounded, size: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Trigger Button (Accessible 44x44 target)
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () => _showUserActionSheet(user),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleAvatar(String name, String role, {double size = 48}) {
    Color bg;
    Color fg;
    IconData icon;

    switch (role) {
      case 'admin':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.security_rounded;
        break;
      case 'owner':
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        icon = Icons.business_center_rounded;
        break;
      case 'staff':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        icon = Icons.badge_rounded;
        break;
      case 'customer':
      default:
        bg = const Color(0xFFF0FDFA);
        fg = const Color(0xFF0D9488);
        icon = Icons.person_rounded;
        break;
    }

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('').toUpperCase()
        : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Center(
        child: initials.length >= 2
            ? Text(
                initials,
                style: GoogleFonts.outfit(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.36,
                  letterSpacing: 0.5,
                ),
              )
            : Icon(icon, color: fg, size: size * 0.48),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (role) {
      case 'admin':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      case 'owner':
        textColor = const Color(0xFF6D28D9);
        bgColor = const Color(0xFFF5F3FF);
        borderColor = const Color(0xFFDDD6FE);
        break;
      case 'staff':
        textColor = const Color(0xFF1D4ED8);
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        break;
      case 'customer':
      default:
        textColor = const Color(0xFF0F766E);
        bgColor = const Color(0xFFF0FDFA);
        borderColor = const Color(0xFF99F6E4);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.outfit(
          color: textColor,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final isActive = status == 'active';
    final dotColor = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bgColor = isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final borderColor = isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
    final label = isActive ? 'ACTIVE' : 'SUSPENDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: dotColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
