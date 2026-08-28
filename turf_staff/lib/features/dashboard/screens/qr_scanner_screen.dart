import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';

class QRScannerScreen extends StatefulWidget {
  final String? expectedBookingId;

  const QRScannerScreen({super.key, this.expectedBookingId});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SCAN BOOKING QR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off_rounded, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded, color: Colors.yellow);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off_rounded, color: Colors.red);
                  default:
                    return const Icon(Icons.flash_off_rounded, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front_rounded, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear_rounded, color: Colors.white);
                  default:
                    return const Icon(Icons.camera_rear_rounded, color: Colors.white);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (!_isScanning) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanning = false);
                  _verifyBooking(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Darkened background with a hole for the scanner
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
        // Scanner border
        Center(
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF4CAF50), width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        // Instruction text
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(
                  widget.expectedBookingId != null ? 'Verifying specific match' : 'Align QR code within the frame',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                ),
                if (widget.expectedBookingId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Target Booking ID: ${widget.expectedBookingId!.substring(widget.expectedBookingId!.length - 6).toUpperCase()}',
                      style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _verifyBooking(String bookingId) async {
    // If we expect a specific booking, check it first
    if (widget.expectedBookingId != null && widget.expectedBookingId != bookingId) {
      _showErrorDialog(
          title: 'MATCH MISMATCH',
          message: 'This QR code is for a different booking. Please scan the correct QR for this customer.'
      );
      return;
    }

    final staff = Provider.of<StaffProvider>(context, listen: false);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
    );

    final success = await staff.verifyBooking(bookingId);
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context, rootNavigator: true).pop(); // Close loading
    }

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
            const SizedBox(height: 24),
            Text('VERIFIED!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Booking confirmed. Match started.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.black54)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('DONE', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({String title = 'INVALID QR', String message = 'This booking could not be verified. Please check manually.'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 80),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.black54)),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isScanning = true);
                  },
                  child: const Text('RETRY'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
