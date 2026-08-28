import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';
import '../widgets/extra_charges_dialog.dart';

class PaymentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);
    final activeBookings = staff.todayBookings.where((b) => b['bookingStatus'] == 'checked-in').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF1ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PAYMENTS & ADD-ONS',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: activeBookings.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: activeBookings.length,
              itemBuilder: (context, index) {
                final booking = activeBookings[index];
                return _buildBookingPaymentCard(context, booking);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            'NO ACTIVE MATCHES',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Check-in a player to manage extra charges',
            style: GoogleFonts.outfit(color: Colors.black12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPaymentCard(BuildContext context, Map<String, dynamic> booking) {
    final extraCharges = (booking['extraCharges'] as List?) ?? [];
    final totalExtra = extraCharges.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking['userId']?['name'] ?? 'WALK-IN PLAYER',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (extraCharges.isEmpty)
            Text('No extra charges added yet', style: GoogleFonts.outfit(color: Colors.black26, fontSize: 12))
          else
            Column(
              children: extraCharges.map((charge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(charge['type'], style: GoogleFonts.outfit(color: Colors.black54)),
                    Text('Rs. ${charge['amount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Extras:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black54)),
              Text('Rs. $totalExtra', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4CAF50), fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (context) => ExtraChargesDialog(booking: booking)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('ADD CHARGE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
