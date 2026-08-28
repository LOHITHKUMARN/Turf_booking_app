import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';

class ExtraChargesDialog extends StatefulWidget {
  final Map<String, dynamic> booking;

  const ExtraChargesDialog({Key? key, required this.booking}) : super(key: key);

  @override
  _ExtraChargesDialogState createState() => _ExtraChargesDialogState();
}

class _ExtraChargesDialogState extends State<ExtraChargesDialog> {
  final _amountController = TextEditingController();
  String _selectedType = 'Equipment';
  bool _isPaid = false;
  bool _isSubmitting = false;

  final List<String> _types = ['Equipment', 'Lighting', 'Extra Time', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Extra Charge',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 24),
              
              // 🔹 Category Label
              Text(
                "Charge Category",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // 🔹 Dropdown Box
              _inputBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                    items: _types.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() => _selectedType = newValue!);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 🔹 Amount Label
              Text(
                "Amount (Rs.)",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // 🔹 Amount Field
              _inputBox(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Enter amount",
                    hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 🔹 Checkbox Row
              Row(
                children: [
                  Checkbox(
                    value: _isPaid,
                    onChanged: (val) => setState(() => _isPaid = val!),
                    activeColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Text(
                    "Cash Received",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 🔥 Premium Button
              GestureDetector(
                onTap: _isSubmitting ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            "ADD CHARGE",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  void _submit() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    final staff = Provider.of<StaffProvider>(context, listen: false);
    
    final success = await staff.addExtraCharge(
      bookingId: widget.booking['_id'],
      type: _selectedType,
      amount: double.parse(_amountController.text),
      isPaid: _isPaid,
    );
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Charge added successfully', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
    }
  }
}
