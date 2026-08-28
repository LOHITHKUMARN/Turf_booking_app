import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/tournament_provider.dart';
import '../../../models/tournament_model.dart';
import '../../../providers/staff_provider.dart';
import '../../dashboard/screens/qr_scanner_screen.dart';

class MatchVerificationScreen extends StatefulWidget {
  final TournamentMatch match;

  const MatchVerificationScreen({super.key, required this.match});

  @override
  _MatchVerificationScreenState createState() => _MatchVerificationScreenState();
}

class _MatchVerificationScreenState extends State<MatchVerificationScreen> {
  final _score1Controller = TextEditingController();
  final _score2Controller = TextEditingController();
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _score1Controller.text = widget.match.score1.toString();
    _score2Controller.text = widget.match.score2.toString();
    _isVerified = widget.match.isVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MATCH VERIFICATION')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMatchHeader(),
            const SizedBox(height: 48),
            if (widget.match.status == 'scheduled')
              _isVerified ? _buildScheduledSection(context) : _buildVerificationRequirement(context)
            else if (widget.match.status == 'ongoing')
              _buildOngoingSection(context)
            else
              _buildCompletedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            'MATCH #${widget.match.id.substring(widget.match.id.length - 4).toUpperCase()}',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(radius: 30, child: Icon(Icons.shield_rounded, size: 30)),
                    const SizedBox(height: 12),
                    Text(
                      widget.match.team1?.name.toUpperCase() ?? 'TBD',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('VS', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.grey[300])),
              ),
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(radius: 30, child: Icon(Icons.shield_rounded, size: 30)),
                    const SizedBox(height: 12),
                    Text(
                      widget.match.team2?.name.toUpperCase() ?? 'TBD',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRequirement(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.verified_user_outlined, size: 60, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          'VERIFICATION REQUIRED',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify the participants before starting',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.black54),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildVerificationButton(
                'SCAN QR',
                Icons.qr_code_scanner_rounded,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerScreen(expectedBookingId: widget.match.id),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildVerificationButton(
                'ENTER ID',
                Icons.pin_rounded,
                Colors.blue,
                () => _showManualIdDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: child,
    );
  }

  void _showManualIdDialog(BuildContext context) {
    final TextEditingController _idController = TextEditingController();
    final String actualShortId = widget.match.id.substring(widget.match.id.length - 6).toUpperCase();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Verify ID',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Match ID',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Enter Match ID (last 6 chars)",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _inputBox(
                  child: TextField(
                    controller: _idController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. $actualShortId',
                      hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.black26),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final input = _idController.text.trim().toUpperCase();
                          if (input == actualShortId) {
                            Navigator.pop(context);
                            setState(() => _isVerified = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Match Verified!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid Match ID', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'VERIFY',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: Opacity(opacity: anim1.value, child: child));
      },
    );
  }

  Widget _buildScheduledSection(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.timer_outlined, size: 60, color: Colors.orange),
        const SizedBox(height: 16),
        const Text('Ready to kick off?'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _updateStatus(context, 'ongoing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text('START MATCH', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildOngoingSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'ENTER FINAL SCORE',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _score1Controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 32),
            Text('-', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(width: 32),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _score2Controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => _finishMatch(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text('COMPLETE & RECORD RESULT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCompletedSection() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, size: 60, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'MATCH COMPLETED',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green[800]),
        ),
        const SizedBox(height: 8),
        Text(
          'Final Score: ${widget.match.score1} - ${widget.match.score2}',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _updateStatus(BuildContext context, String status) async {
    final success = await Provider.of<TournamentProvider>(context, listen: false).updateMatchStatus(widget.match.id, status);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void _finishMatch(BuildContext context) async {
    final s1 = int.tryParse(_score1Controller.text) ?? 0;
    final s2 = int.tryParse(_score2Controller.text) ?? 0;
    
    final success = await Provider.of<TournamentProvider>(context, listen: false).updateMatchStatus(
      widget.match.id, 
      'completed',
      score1: s1,
      score2: s2,
    );
    
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
