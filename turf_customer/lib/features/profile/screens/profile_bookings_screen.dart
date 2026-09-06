import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../booking/screens/booking_details_screen.dart';
import '../../booking/widgets/add_review_dialog.dart';

class ProfileBookingsScreen extends StatefulWidget {
  const ProfileBookingsScreen({Key? key}) : super(key: key);

  @override
  _ProfileBookingsScreenState createState() => _ProfileBookingsScreenState();
}

class _ProfileBookingsScreenState extends State<ProfileBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false).fetchMyBookings());
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final upcomingBookings = bookingProvider.myBookings.where((b) => 
      b['bookingStatus'] == 'confirmed' || b['bookingStatus'] == 'checked-in').toList();
    final pastBookings = bookingProvider.myBookings.where((b) => 
      b['bookingStatus'] == 'completed' || b['bookingStatus'] == 'cancelled').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: bookingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildBookingList(upcomingBookings, 'No upcoming matches'),
                        _buildBookingList(pastBookings, 'No match history'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, String emptyMsg) {
    if (bookings.isEmpty) {
      return _buildEmptyState(emptyMsg);
    }
    return RefreshIndicator(
      onRefresh: () => Provider.of<BookingProvider>(context, listen: false).fetchMyBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildPremiumCard(bookings[index]),
      ),
    );
  }

  Widget _buildPremiumCard(dynamic booking) {
    final turf = booking['turfId'];
    final slot = booking['slotId'];
    if (turf == null || slot == null) return const SizedBox.shrink();

    final date = DateTime.parse(booking['bookingDate']);
    final status = booking['bookingStatus'] ?? 'confirmed';
    final isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Top Section with Gradient Accent
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.withOpacity(0.03)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: (turf is Map && turf['images'] != null && (turf['images'] as List).isNotEmpty)
                          ? Image.network(
                              ApiConstants.getFullUrl(turf['images'][0]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.green[50],
                                child: const Icon(Icons.sports_soccer, color: Colors.green),
                              ),
                            )
                          : Container(color: Colors.green[50], child: const Icon(Icons.sports_soccer, color: Colors.green)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turf['name'] ?? 'Turf',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                DateFormat('EEEE, dd MMM').format(date),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${slot['startTime']}${booking['groundName'] != null && booking['groundName'] != '' ? ' (${booking['groundName']})' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),
            ),
            // Bottom Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: Colors.green.withOpacity(0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount Paid', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
                        Text(
                          '₹${booking['totalAmount']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted) ...[
                        if (booking['reviewId'] == null && booking['review'] == null)
                          TextButton(
                            onPressed: () => _showReviewDialog(turf, booking),
                            child: Text('RATE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber[800])),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  (booking['reviewId'] != null && booking['reviewId']['rating'] != null)
                                      ? '${booking['reviewId']['rating']}★ RATED'
                                      : (booking['review'] != null && booking['review']['rating'] != null)
                                          ? '${booking['review']['rating']}★ RATED'
                                          : 'RATED',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailsScreen(booking: booking))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green[800],
                          elevation: 0,
                          side: BorderSide(color: Colors.green[800]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('DETAILS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.blue; break;
      case 'checked-in': color = Colors.green; break;
      case 'completed': color = Colors.grey; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  void _showReviewDialog(dynamic turf, dynamic booking) async {
    final turfId = turf is Map ? (turf['_id'] ?? turf['id'] ?? '') : '';
    final bookingId = booking is Map ? (booking['_id'] ?? booking['id'] ?? '') : '';
    final turfName = turf is Map ? (turf['name'] ?? 'Turf') : 'Turf';

    final result = await showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        turfId: turfId.toString(),
        bookingId: bookingId.toString(),
        turfName: turfName.toString(),
      ),
    );
    if (result == true && mounted) {
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    }
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.sports_soccer_outlined, size: 64, color: Colors.green[200]),
          ),
          const SizedBox(height: 20),
          Text(msg, style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
                Expanded(
                  child: Text(
                    'My Bookings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: 'UPCOMING'),
              Tab(text: 'HISTORY'),
            ],
          ),
        ],
      ),
    );
  }
}
