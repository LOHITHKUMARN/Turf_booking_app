import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/turf_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../turfs/screens/add_turf_screen.dart';
import '../../slots/screens/manage_slots_screen.dart';
import '../../slots/screens/slot_rules_screen.dart';

class ManageVenuesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Venues'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => turfProvider.fetchMyTurfs(),
        child: turfProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : turfProvider.turfs.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: turfProvider.turfs.length,
                    itemBuilder: (context, index) {
                      final turf = turfProvider.turfs[index];
                      return _buildTurfCard(context, turf);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-turf'),
        backgroundColor: const Color(0xFF00A86B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTurfCard(BuildContext context, turf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[100],
              child: turf.images.isNotEmpty
                  ? Image.network(
                      ApiConstants.getImageUrl(turf.images[0]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Icon(Icons.landscape_outlined, size: 48, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(turf.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.roofing_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(turf.turfType.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(turf.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(context, Icons.schedule, 'Slots', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SlotManagementScreen(turf: turf)));
                    }),
                    _buildActionButton(context, Icons.edit_note, 'Edit', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddTurfScreen(turf: turf)));
                    }),
                    _buildActionButton(context, Icons.settings_suggest, 'Rules', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SlotRulesScreen(turf: turf)));
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? const Color(0xFF00A86B) : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00A86B), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stadium_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No venues found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-turf'),
            child: const Text('Add Your First Venue'),
          ),
        ],
      ),
    );
  }
}
