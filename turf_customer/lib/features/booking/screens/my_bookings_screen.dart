import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/constants/api_constants.dart';
import 'booking_details_screen.dart';
import '../widgets/add_review_dialog.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false).fetchMyBookings());
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => bookingProvider.fetchMyBookings(),
              child: bookingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bookingProvider.myBookings.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookingProvider.myBookings.length,
                          itemBuilder: (context, index) {
                            return _buildBookingCard(bookingProvider.myBookings[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final turf = booking['turfId'];
    final slot = booking['slotId'];
    
    if (turf == null || slot == null) {
      return const SizedBox.shrink(); // Hide invalid bookings
    }
    
    final date = DateTime.parse(booking['bookingDate']);
    final status = booking['bookingStatus'] ?? 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: (turf is Map && turf['images'] != null && (turf['images'] as List).isNotEmpty)
                        ? Image.network(() {
                            String img = turf['images'][0];
                            if (img.startsWith('/')) {
                              final base = ApiConstants.baseUrl.replaceAll('/api', '');
                              return '$base$img';
                            }
                            return img;
                          }(), fit: BoxFit.cover)
                        : const Icon(Icons.stadium_outlined),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((turf is Map ? turf['name'] : 'Turf') ?? 'Turf', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(date)} | ${slot['startTime']}',
                        style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Paid', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                    Text('₹${booking['totalAmount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailsScreen(booking: booking),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('VIEW DETAILS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          if (status == 'completed')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: booking['reviewId'] == null
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => AddReviewDialog(
                              turfId: turf is Map ? turf['_id'] : '',
                              bookingId: booking['_id'],
                              turfName: turf is Map ? turf['name'] : 'Turf',
                            ),
                          );
                          // Refresh to show updated states
                          if (mounted) {
                            Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
                          }
                        },
                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                        label: const Text('RATE YOUR MATCH'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[800],
                          side: BorderSide(color: Colors.amber[800]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'MATCH RATED',
                              style: GoogleFonts.outfit(
                                color: Colors.amber[900],
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: List.generate(5, (index) {
                                final rating = (booking['reviewId'] != null && booking['reviewId']['rating'] != null)
                                    ? (booking['reviewId']['rating'] as num).toDouble()
                                    : 0.0;
                                return Icon(
                                  index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber[600],
                                  size: 16,
                                );
                              }),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.blue; break;
      case 'checked-in': color = Colors.green; break;
      case 'completed': color = Colors.grey; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No bookings found', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text('Explore Turfs', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[900]!, Colors.green[700]!],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 48), // Spacer for title centering
                Expanded(
                  child: Text(
                    'My Bookings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your matches and sessions',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
