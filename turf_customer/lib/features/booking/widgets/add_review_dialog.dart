import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/providers/booking_provider.dart';

class AddReviewDialog extends StatefulWidget {
  final String turfId;
  final String bookingId;
  final String turfName;

  const AddReviewDialog({
    super.key,
    required this.turfId,
    required this.bookingId,
    required this.turfName,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return '⭐ Excellent Experience!';
    if (rating >= 4) return '👍 Great Match!';
    if (rating >= 3) return '👌 Good Play';
    if (rating >= 2) return '😐 Average';
    return '👎 Needs Improvement';
  }

  void _handleSubmit(ReviewProvider reviewProvider) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await reviewProvider.addReview(
        turfId: widget.turfId,
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (success && mounted) {
        final bookingProv = Provider.of<BookingProvider>(context, listen: false);
        bookingProv.markBookingAsReviewed(widget.bookingId, _rating, _commentController.text.trim());
        bookingProv.fetchMyBookings();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your rating has been recorded.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        final errorMsg = reviewProvider.errorMessage ?? 'Failed to submit review or already reviewed.';
        if (errorMsg.toLowerCase().contains('already reviewed')) {
          final bookingProv = Provider.of<BookingProvider>(context, listen: false);
          bookingProv.markBookingAsReviewed(widget.bookingId, _rating, _commentController.text.trim());
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final isBusy = reviewProvider.isLoading || _isSubmitting;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate your match at',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              widget.turfName,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Responsive star rating row with zero overflow guarantee
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final isSelected = index < _rating;
                return GestureDetector(
                  onTap: isBusy ? null : () => setState(() => _rating = index + 1.0),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber[600],
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _getRatingText(_rating),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber[800],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _commentController,
              maxLines: 3,
              enabled: !isBusy,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isBusy ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => _handleSubmit(reviewProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isBusy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('SUBMIT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
