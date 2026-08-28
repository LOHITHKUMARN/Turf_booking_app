import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:convert';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.usersUrl);
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiService.post(
        ApiConstants.userStatusUrl,
        {'userId': userId, 'status': status},
      );
      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('STATUS UPDATED: ${status.toUpperCase()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
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
        title: Text('USER DIRECTORY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: Colors.white)),
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
        onRefresh: _fetchUsers,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
            : _users.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildExecutiveUserCard(user);
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white, 
              shape: BoxShape.circle, 
              boxShadow: AppTheme.softShadow
            ),
            child: const Icon(Icons.supervised_user_circle_rounded, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "NO RECORDS FOUND",
            style: GoogleFonts.outfit(color: AppTheme.textMain, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            "Try refreshing the sync records.",
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveUserCard(dynamic user) {
    final status = user['status'] ?? 'active';
    final isActive = status == 'active';
    final role = user['role'] ?? 'customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['name'].toUpperCase(),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textMain, fontSize: 14, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildExecutiveRoleBadge(role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'],
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor : Colors.redAccent, 
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? AppTheme.primaryColor : Colors.redAccent).withOpacity(0.3),
                            blurRadius: 4,
                          )
                        ]
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(color: isActive ? AppTheme.primaryColor : Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.tune_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'active',
                enabled: status != 'active',
                child: Text('WHITELIST USER', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
              ),
              PopupMenuItem(
                value: 'blocked',
                enabled: status != 'blocked',
                child: Text('TERMINATE ACCESS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.redAccent)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('DELETE ACCOUNT', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red.shade900)),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(user['_id'], user['name']);
              } else {
                _updateUserStatus(user['_id'], value);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('DELETE USER?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.red.shade900)),
        content: Text('This will permanently remove "$name" and all associated data. This action is irreversible.', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId);
            },
            child: Text('DELETE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.delete('${ApiConstants.deleteUserUrl}/$userId');
      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('USER DELETED PERMANENTLY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deletion failed')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Widget _buildExecutiveRoleBadge(String role) {
    final isOwner = role == 'owner';
    final color = isOwner ? AppTheme.primaryDark : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
