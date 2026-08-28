import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/turf_model.dart';
import '../../../providers/turf_provider.dart';

class SlotRulesScreen extends StatefulWidget {
  final Turf turf;

  const SlotRulesScreen({Key? key, required this.turf}) : super(key: key);

  @override
  _SlotRulesScreenState createState() => _SlotRulesScreenState();
}

class _SlotRulesScreenState extends State<SlotRulesScreen> {
  double _minDuration = 1.0;
  double _advanceLimit = 7.0;
  double _cutoffTime = 2.0;
  double _gracePeriod = 15.0;
  double _maxMembers = 10.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _minDuration = (widget.turf.settings.minBookingDuration ?? 1).toDouble();
    _advanceLimit = (widget.turf.settings.advanceBookingLimit ?? 7).toDouble();
    _cutoffTime = (widget.turf.settings.bookingCutoffTime ?? 2).toDouble();
    _gracePeriod = (widget.turf.settings.gracePeriod ?? 15).toDouble();
    _maxMembers = (widget.turf.settings.maxMembers ?? 10).toDouble();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await Provider.of<TurfProvider>(context, listen: false).updateTurfSettings(
      widget.turf.id,
      {
        'minBookingDuration': _minDuration.toInt(),
        'advanceBookingLimit': _advanceLimit.toInt(),
        'bookingCutoffTime': _cutoffTime.toInt(),
        'gracePeriod': _gracePeriod.toInt(),
        'maxMembers': _maxMembers.toInt(),
      },
    );

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Slot Rules: ${widget.turf.name}'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleSlider(
              'Minimum Booking Duration',
              '${_minDuration.toInt()} Hours',
              'Set the minimum time a user can book for.',
              _minDuration,
              1,
              5,
              (v) => setState(() => _minDuration = v),
              Icons.timer_outlined,
            ),
            const SizedBox(height: 20),
            _buildRuleSlider(
              'Advance Booking Limit',
              '${_advanceLimit.toInt()} Days',
              'How many days in advance can a user book?',
              _advanceLimit,
              1,
              30,
              (v) => setState(() => _advanceLimit = v),
              Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 20),
            _buildRuleSlider(
              'Booking Cutoff Time',
              '${_cutoffTime.toInt()} Hours',
              'Bookings close X hours before slot starts.',
              _cutoffTime,
              0,
              24,
              (v) => setState(() => _cutoffTime = v),
              Icons.lock_clock_outlined,
            ),
            const SizedBox(height: 20),
            _buildRuleSlider(
              'Grace Period',
              '${_gracePeriod.toInt()} Minutes',
              'Extra time allowed for check-in.',
              _gracePeriod,
              0,
              60,
              (v) => setState(() => _gracePeriod = v),
              Icons.more_time_outlined,
            ),
            const SizedBox(height: 20),
            _buildRuleSlider(
              'Maximum Members Allowed',
              '${_maxMembers.toInt()} Members',
              'Set the capacity limit for this venue.',
              _maxMembers,
              1,
              50,
              (v) => setState(() => _maxMembers = v),
              Icons.groups_outlined,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Configuration',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSlider(
    String title,
    String valueText,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF00A86B), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toInt()}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(
                valueText,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF00A86B)),
              ),
              Text('${max.toInt()}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: const Color(0xFF00A86B),
            inactiveColor: const Color(0xFF00A86B).withOpacity(0.1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
