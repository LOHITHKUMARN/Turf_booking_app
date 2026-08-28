import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/turf_provider.dart';

import '../../../core/services/socket_service.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshBookings();

    // Listen for real-time booking updates
    SocketService().on('booking_updated', _handleSocketEvent);
    SocketService().on('slotBooked', _handleSocketEvent);
  }

  void _handleSocketEvent(dynamic data) {
    if (mounted) {
      setState(() {
        _refreshBookings();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Booking list updated in real-time'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _refreshBookings() {
    _bookingsFuture = Provider.of<TurfProvider>(context, listen: false).fetchBookings();
  }

  @override
  void dispose() {
    SocketService().off('booking_updated');
    SocketService().off('slotBooked');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Booking Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final date = DateTime.parse(booking['bookingDate']);
              
              return _buildBookingCard(context, booking, date);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/manual-booking'),
        backgroundColor: const Color(0xFF00A86B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, dynamic booking, DateTime date) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking['turfId']?['name'] ?? 'Unknown Venue',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                _buildPaymentStatusBadge(booking['paymentStatus'] ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(Icons.person_outline, booking['userId']?['name'] ?? 'Guest'),
                const Spacer(),
                _buildInfoChip(Icons.calendar_today_outlined, DateFormat('MMM dd, yyyy').format(date)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.access_time_outlined, '${booking['slotId']?['startTime'] ?? '--'} - ${booking['slotId']?['endTime'] ?? '--'}'),
                const Spacer(),
                Text(
                  'Rs. ${booking['totalAmount']}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00A86B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sport: ${booking['slotId']?['sport'] ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final isPaid = status == 'paid';
    final color = isPaid ? const Color(0xFF00A86B) : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPaid ? Icons.check_circle : Icons.pending, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 80, color: Colors.green[100]),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            'Keep sharing your venue to get bookings!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
