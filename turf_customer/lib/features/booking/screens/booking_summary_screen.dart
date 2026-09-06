import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/turf_model.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Turf turf;
  final dynamic slot;
  final DateTime date;

  const BookingSummaryScreen({
    required this.turf,
    required this.slot,
    required this.date,
  });

  @override
  _BookingSummaryScreenState createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  bool _isSuccess = false;
  String _newBookingId = '';

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessView();

    final basePrice = (widget.slot['price'] ?? 0).toDouble();
    final taxRate = widget.turf.taxPercentage / 100;
    final taxAmount = basePrice * taxRate;
    final totalAmount = basePrice + taxAmount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Booking Summary', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTurfCard(),
            const SizedBox(height: 24),
            _buildBillDetails(basePrice, taxAmount, totalAmount),
            const SizedBox(height: 24),
            _buildPaymentSelection(),
            const SizedBox(height: 32),
            if (_paymentMethod == 'upi') _buildUPIDetails(totalAmount),
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmButton(totalAmount),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 100),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your slot at ${widget.turf.name} is reserved. Show this QR at the venue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: QrImageView(
                  data: _newBookingId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'BOOKING ID: ${_newBookingId.toUpperCase().padLeft(8, '0').substring(_newBookingId.length > 8 ? _newBookingId.length - 8 : 0)}',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('EXPLORE MORE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurfCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.turf.firstImageUrl != null && widget.turf.firstImageUrl!.isNotEmpty
                  ? Image.network(
                      ApiConstants.getFullUrl(widget.turf.firstImageUrl),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.green[50],
                        child: const Icon(Icons.sports_soccer, color: Colors.green),
                      ),
                    )
                  : Container(
                      color: Colors.green[50],
                      child: const Icon(Icons.sports_soccer, color: Colors.green),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.turf.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(widget.date)} | ${widget.slot['startTime']}',
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.slot['sport'] ?? 'Sport'}${widget.slot['groundName'] != null && widget.slot['groundName'] != '' ? ' | ${widget.slot['groundName']}' : ''}',
                  style: GoogleFonts.outfit(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    if (value == value.roundToDouble()) {
      return '₹${NumberFormat('#,##,###').format(value.toInt())}';
    }
    return '₹${NumberFormat('#,##,###.##').format(value)}';
  }

  Widget _buildBillDetails(double base, double tax, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildBillRow('Base Amount', _formatCurrency(base)),
          const SizedBox(height: 12),
          _buildBillRow('Taxes (${widget.turf.taxPercentage}%)', _formatCurrency(tax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_formatCurrency(total), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green[800])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildPaymentOption('cash', 'Pay at Ground', Icons.payments_outlined),
        const SizedBox(height: 12),
        _buildPaymentOption('upi', 'Pay via UPI', Icons.qr_code_scanner_rounded),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String label, IconData icon) {
    bool isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50]?.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.green[800]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green[800] : Colors.grey[600]),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: Colors.green[800]),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIDetails(double amount) {
    if (widget.turf.upiId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
        child: Text('UPI not configured for this turf yet.', style: TextStyle(color: Colors.amber[900])),
      );
    }

    final upiUri = 'upi://pay?pa=${widget.turf.upiId}&pn=${widget.turf.name}&am=$amount&cu=INR';

    return Center(
      child: Column(
        children: [
          QrImageView(
            data: upiUri,
            version: QrVersions.auto,
            size: 200.0,
          ),
          const SizedBox(height: 8),
          Text('Scan to pay via any UPI app', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
          Text(widget.turf.upiId, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _processBooking(total),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isProcessing
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('CONFIRM & BOOK', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _processBooking(double total) async {
    try {
      setState(() => _isProcessing = true);
      final provider = Provider.of<BookingProvider>(context, listen: false);
      
      print('DEBUG: Sending booking request for turf: ${widget.turf.id}');

      final booking = await provider.bookSlot(
        turfId: widget.turf.id,
        slotId: widget.slot['_id'],
        date: widget.date,
        amount: total,
        paymentMethod: _paymentMethod,
      );

      print('DEBUG: Booking request finished. Result: $booking');
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (booking != null && booking['_id'] != null) {
            _newBookingId = booking['_id'].toString();
            _isSuccess = true;
          }
        });
      }

      if (booking == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book. Slot might already be taken.'),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: CRITICAL UI ERROR: $e');
      if (mounted) setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
