import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_issue_screen.dart';

class SafetyScreen extends StatefulWidget {
  @override
  _SafetyScreenState createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final List<Map<String, dynamic>> _safetyRules = [
    {'title': 'No Spikes on Turf', 'checked': true},
    {'title': 'First Aid Kit Checked', 'checked': true},
    {'title': 'Lighting Inspection Done', 'checked': false},
    {'title': 'Emergency Exit Clear', 'checked': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SAFETY & COMPLIANCE',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Report
            _buildActionCard(
              'Report Incident',
              'Report injury, crowd issue, or damage',
              Icons.warning_amber_rounded,
              Colors.redAccent,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen())),
            ),
            const SizedBox(height: 32),
            
            Text(
              'SAFETY CHECKLIST',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.black38),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: _safetyRules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rule = entry.value;
                    return _buildCheckItem(index, rule['title'], rule['checked']);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildComplianceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), // Light red background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red.shade900)),
                  Text(subtitle, style: GoogleFonts.outfit(color: Colors.red.shade700.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.red.shade200, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(int index, String title, bool checked) {
    return ListTile(
      onTap: () => setState(() => _safetyRules[index]['checked'] = !_safetyRules[index]['checked']),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.black.withOpacity(0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(
          checked ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          color: checked ? const Color(0xFF4CAF50) : Colors.black12,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: checked ? Colors.black87 : Colors.black26,
        ),
      ),
      trailing: checked 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "DONE",
                style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            )
          : null,
    );
  }

  Widget _buildComplianceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'COMPLIANCE STATUS',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          _buildComplianceStat('Staff Rules Signed', '100%', const Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          _buildComplianceStat('Incident Response readiness', 'High', const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildComplianceStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black54)),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
