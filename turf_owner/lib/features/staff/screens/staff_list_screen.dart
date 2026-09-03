import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';
import 'manage_staff_screen.dart';
import 'staff_attendance_screen.dart';

class StaffListScreen extends StatefulWidget {
  @override
  _StaffListScreenState createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<TurfProvider>(context, listen: false).fetchStaff());
  }

  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Ground Staff'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined, color: Colors.blue),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StaffAttendanceScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageStaffScreen()),
            ).then((_) => turfProvider.fetchStaff()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: turfProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : turfProvider.staff.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: turfProvider.staff.length,
                  itemBuilder: (context, index) => _buildStaffCard(turfProvider.staff[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.green[100]),
          const SizedBox(height: 16),
          Text(
            'No staff members found',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Add staff to help manage your venues',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageStaffScreen()),
            ).then((_) => Provider.of<TurfProvider>(context, listen: false).fetchStaff()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            child: const Text('ADD STAFF'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(dynamic staff) {
    final assignedTurf = staff['assignedTurfId'];
    String? turfName;
    if (assignedTurf is Map) {
      turfName = assignedTurf['name']?.toString();
    } else if (assignedTurf != null && assignedTurf.toString().isNotEmpty) {
      turfName = assignedTurf.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00A86B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: Color(0xFF00A86B)),
        ),
        title: Text(
          staff['name'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff['email'], style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: turfName != null ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                turfName != null 
                    ? 'Turf: $turfName${staff['assignedGround'] != null && staff['assignedGround'] != '' ? ' (${staff['assignedGround']})' : ''}' 
                    : 'NOT ASSIGNED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: turfName != null ? Colors.blue : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffAttendanceScreen(staff: staff),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined, color: Color(0xFF00A86B)),
              onPressed: () => _showAssignTurfDialog(staff),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTurfDialog(dynamic staff) {
    final turfProvider = Provider.of<TurfProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Assign Turf',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign ${staff['name']} to a venue:',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: turfProvider.turfs.length,
                  itemBuilder: (context, index) {
                    final turf = turfProvider.turfs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.stadium_outlined, color: Color(0xFF00A86B)),
                      title: Text(turf.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(turf.area, style: const TextStyle(fontSize: 12)),
                      onTap: () async {
                        if (turf.grounds.isNotEmpty) {
                          Navigator.pop(context);
                          _showAssignGroundDialog(staff, turf);
                        } else {
                          final success = await turfProvider.assignTurfToStaff(staff['_id'], turf.id);
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Turf assigned successfully!')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showAssignGroundDialog(dynamic staff, Turf turf) {
    final turfProvider = Provider.of<TurfProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Select Ground',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign ${staff['name']} to a specific ground at ${turf.name}:',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: turf.grounds.length,
                  itemBuilder: (context, index) {
                    final ground = turf.grounds[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
                      title: Text(ground, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final staffId = staff['_id'] ?? staff['id'];
                        final success = await turfProvider.assignTurfToStaff(staffId, turf.id, groundName: ground);
                        navigator.pop();
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Staff assigned to ground successfully!')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
