import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';

class AnnouncementScreen extends StatefulWidget {
  @override
  _AnnouncementScreenState createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<StaffProvider>(context, listen: false).fetchAnnouncements());
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ANNOUNCEMENTS',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: staff.announcements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: staff.announcements.length,
              itemBuilder: (context, index) {
                final announcement = staff.announcements[index];
                return _buildAnnouncementCard(announcement);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            "No announcements yet",
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final date = DateTime.parse(announcement['createdAt']);
    final type = announcement['type'] ?? 'General';

    Color categoryColor = Colors.green;
    if (type == 'Alert' || type == 'Emergency') categoryColor = Colors.red;
    if (type == 'Update') categoryColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          // Add interaction later
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: categoryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(date),
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                  )
                ],
              ),

              const SizedBox(height: 12),

              // 📝 TITLE
              Row(
                children: [
                  Icon(
                    type == 'Alert' || type == 'Emergency' 
                        ? Icons.error_outline_rounded 
                        : Icons.campaign_rounded, 
                    color: categoryColor, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement['title'],
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 📄 DESCRIPTION
              Text(
                announcement['message'],
                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
              ),

              const SizedBox(height: 12),

              // 👉 ACTION
              Text(
                "View Details →",
                style: GoogleFonts.outfit(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
