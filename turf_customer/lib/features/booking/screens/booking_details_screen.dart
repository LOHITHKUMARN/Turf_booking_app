import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/constants/api_constants.dart';

class BookingDetailsScreen extends StatelessWidget {
  final dynamic booking;

  const BookingDetailsScreen({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final turf = booking['turfId'];
    final slot = booking['slotId'];
    final date = DateTime.parse(booking['bookingDate']);
    final status = booking['bookingStatus'] ?? 'confirmed';

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTicket(context, turf, slot, date, status),
            const SizedBox(height: 32),
            _buildActions(context, status),
          ],
        ),
      ),
    );
  }

  Widget _buildTicket(BuildContext context, dynamic turf, dynamic slot, DateTime date, String status) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Image and Basic Info
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: (turf is Map && turf['images'] != null && (turf['images'] as List).isNotEmpty)
                      ? Image.network(
                          () {
                            String img = turf['images'][0];
                            if (img.startsWith('/')) {
                              final base = ApiConstants.baseUrl.replaceAll('/api', '');
                              return '$base$img';
                            }
                            return img;
                          }(),
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.green[100], child: const Icon(Icons.stadium, size: 50, color: Colors.green)),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildStatusBadge(status),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turf['name'] ?? 'Turf Name',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (turf is Map && turf['location'] is Map)
                            ? '${turf['location']['area']}, ${turf['location']['city']}'
                            : 'Location not available',
                        style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('DATE', DateFormat('dd MMM yyyy').format(date)),
                    _buildInfoColumn('TIME', slot['startTime'] ?? '--:--'),
                    _buildInfoColumn('SPORT', slot['sport']?.toString().toUpperCase() ?? 'OTHER'),
                  ],
                ),
              ],
            ),
          ),

          // Dashed Divider with side cutouts (Ticket look)
          Row(
            children: [
              _buildHalfCircle(context: context, isLeft: true),
              Expanded(child: _buildDashedLine()),
              _buildHalfCircle(context: context, isLeft: false),
            ],
          ),

          // Bottom Section: QR Code and Booking ID
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Keep QR white for scannability
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: QrImageView(
                    data: booking['_id'],
                    version: QrVersions.auto,
                    size: 160.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BOOKING ID: ${booking['_id'].toString().substring(booking['_id'].toString().length - 6).toUpperCase()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan this QR code at the entry',
                  style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700])),
                    Text(
                      '₹${booking['totalAmount']}',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500], letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed': color = Colors.blue; break;
      case 'checked-in': color = Colors.green; break;
      case 'completed': color = Colors.grey; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHalfCircle({required BuildContext context, required bool isLeft}) {
    return Container(
      height: 24,
      width: 12,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: isLeft
            ? const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24))
            : const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 5.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
            );
          }),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, String status) {
    final canCancel = status.toLowerCase() == 'confirmed';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Open support dialer or email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contacting support...')),
              );
            },
            icon: const Icon(Icons.headset_mic_outlined),
            label: const Text('CONTACT SUPPORT'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (canCancel) ...[
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('CANCEL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<BookingProvider>(context, listen: false).cancelBooking(booking['_id']);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled successfully')),
                );
                Navigator.pop(context); // Go back to list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to cancel booking')),
                );
              }
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
