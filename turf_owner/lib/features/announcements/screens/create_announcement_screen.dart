import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/turf_provider.dart';
import '../../../models/turf_model.dart';
import '../../../core/theme/app_theme.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String? initialTurfId;
  final String? initialTitle;

  const CreateAnnouncementScreen({
    super.key,
    this.initialTurfId,
    this.initialTitle,
  });

  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'General';
  bool _isPublic = false;
  bool _isSubmitting = false;
  Turf? _selectedTurf;

  final List<String> _types = ['General', 'Emergency', 'Shift Update'];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    final turfProvider = Provider.of<TurfProvider>(context, listen: false);
    if (turfProvider.turfs.isEmpty) {
      turfProvider.fetchMyTurfs().then((_) {
        if (mounted && turfProvider.turfs.isNotEmpty) {
          setState(() {
            if (widget.initialTurfId != null) {
              _selectedTurf = turfProvider.turfs.firstWhere(
                (t) => t.id == widget.initialTurfId,
                orElse: () => turfProvider.turfs.first,
              );
            } else {
              _selectedTurf = turfProvider.turfs.first;
            }
          });
        }
      });
    } else {
      if (widget.initialTurfId != null) {
        _selectedTurf = turfProvider.turfs.firstWhere(
          (t) => t.id == widget.initialTurfId,
          orElse: () => turfProvider.turfs.first,
        );
      } else {
        _selectedTurf = turfProvider.turfs.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfProvider = Provider.of<TurfProvider>(context);
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NEW ANNOUNCEMENT',
          style: GoogleFonts.outfit(
            color: AppTheme.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("SELECT VENUE"),
              _buildTurfDropdown(turfProvider),
              const SizedBox(height: 32),
              _buildSectionHeader("ANNOUNCEMENT CONTENT"),
              _buildTextField(
                controller: _titleController,
                label: "NOTICE TITLE",
                hint: "E.g., RAIN UPDATE",
                validator: (v) => v!.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _messageController,
                label: "MESSAGE DETAILS",
                hint: "PROVIDE CLEAR INSTRUCTIONS...",
                maxLines: 4,
                validator: (v) => v!.isEmpty ? "Message is required" : null,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader("BROADCAST SETTINGS"),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildPublicToggle(),
              const SizedBox(height: 48),
              _buildSubmitButton(announcementProvider),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppTheme.textSecondary.withOpacity(0.5),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTurfDropdown(TurfProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Turf>(
          value: _selectedTurf,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: GoogleFonts.outfit(color: AppTheme.textMain, fontWeight: FontWeight.w600),
          items: provider.turfs.map((t) => DropdownMenuItem(
            value: t, 
            child: Text(t.name.toUpperCase())
          )).toList(),
          onChanged: (val) => setState(() => _selectedTurf = val),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMain, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w800),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _types.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.black.withOpacity(0.05)),
              boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 10)] : [],
            ),
            child: Text(
              type.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPublicToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PUBLIC BROADCAST",
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMain, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  "Make this notice visible to all customers on the app.",
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _isPublic,
            onChanged: (val) => setState(() => _isPublic = val),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AnnouncementProvider provider) {
    final isBusy = provider.isLoading || _isSubmitting;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isBusy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        child: isBusy
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                'LAUNCH ANNOUNCEMENT',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
      ),
    );
  }

  void _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate() || _selectedTurf == null) return;

    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<AnnouncementProvider>(context, listen: false);
      final success = await provider.createAnnouncement(
        turfId: _selectedTurf!.id,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        isPublic: _isPublic,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ANNOUNCEMENT BROADCASTED!", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
