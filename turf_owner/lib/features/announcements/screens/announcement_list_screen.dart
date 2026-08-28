import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/announcement_provider.dart';
import '../../../models/announcement_model.dart';
import '../../../core/theme/app_theme.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AnnouncementProvider>(context, listen: false).fetchAnnouncements());
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ANNOUNCEMENTS',
          style: GoogleFonts.outfit(
            color: AppTheme.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: announcementProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : announcementProvider.announcements.isEmpty
              ? _buildEmptyState()
              : _buildListView(announcementProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-announcement'),
        backgroundColor: AppTheme.primaryColor,
        label: Text(
          'NEW ANNOUNCEMENT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppTheme.primaryColor.withOpacity(0.05), blurRadius: 20)
              ],
            ),
            child: const Icon(Icons.campaign_outlined, size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "NO ANNOUNCEMENTS",
            style: GoogleFonts.outfit(
              color: AppTheme.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Share updates with your staff and customers",
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(AnnouncementProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: provider.announcements.length,
      itemBuilder: (context, index) {
        final announcement = provider.announcements[index];
        return _buildAnnouncementCard(context, announcement, provider);
      },
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement announcement, AnnouncementProvider provider) {
    final isEmergency = announcement.type == 'Emergency';
    final typeColor = isEmergency ? Colors.redAccent : AppTheme.primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(announcement.type, typeColor),
                IconButton(
                  onPressed: () => _confirmDelete(context, announcement, provider),
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.3), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              announcement.title.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppTheme.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.message,
              style: GoogleFonts.poppins(color: AppTheme.textMain.withOpacity(0.7), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    announcement.isPublic ? "PUBLIC" : "STAFF ONLY",
                    style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(announcement.createdAt),
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (announcement.turfName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.stadium_rounded, size: 12, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    announcement.turfName!.toUpperCase(),
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Announcement announcement, AnnouncementProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        title: Text("DELETE ANNOUNCEMENT?", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textMain)),
        content: Text("This will permanently remove the update.", style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAnnouncement(announcement.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("REMOVED", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text("DELETE", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
