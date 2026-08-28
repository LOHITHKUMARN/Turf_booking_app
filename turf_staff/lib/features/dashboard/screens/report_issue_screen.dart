import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/auth_provider.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Ground';
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isSafetyIncident = false;

  final List<String> _maintenanceCategories = ['Ground', 'Lights', 'Amenities', 'Other'];
  final List<String> _safetyCategories = ['Injury', 'Damage', 'Crowd Issue', 'Other'];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a description', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final turfId = auth.user?['assignedTurfId'];

      if (turfId == null) return;

      // 1. Upload images sequentially
      List<String> uploadedUrls = [];
      for (var file in _selectedImages) {
        final url = await staff.uploadImage(file);
        if (url != null) uploadedUrls.add(url);
      }

      // 2. Submit report
      final success = _isSafetyIncident 
        ? await staff.reportIncident(
            turfId: turfId,
            type: _selectedCategory,
            severity: 'Medium', // Default severity
            description: _descController.text.trim(),
            images: uploadedUrls,
          )
        : await staff.reportIssue(
            turfId: turfId,
            category: _selectedCategory,
            description: _descController.text.trim(),
            images: uploadedUrls,
          );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert sent to owner successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
          'ALERT OWNER',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💎 Redesigned Top Tabs (High Depth)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildToggleItem(false, 'MAINTENANCE', Icons.build_rounded),
                      _buildToggleItem(true, 'SAFETY ALERT', Icons.security_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Category Selector
                Text(
                  'What is the issue about?',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: (_isSafetyIncident ? _safetyCategories : _maintenanceCategories).map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.black.withOpacity(0.05),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Description Field
                Text(
                  'Detailed Description',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue or incident here...',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                      contentPadding: const EdgeInsets.all(20),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Photo Attachments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Photos',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    Text(
                      '${_selectedImages.length} SELECTED',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF4CAF50)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAddPhotoButton(onTap: _takePhoto, icon: Icons.camera_alt_rounded, label: 'Camera'),
                      const SizedBox(width: 12),
                      _buildAddPhotoButton(onTap: _pickImage, icon: Icons.photo_library_rounded, label: 'Gallery'),
                      ...List.generate(_selectedImages.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: Text(
                      'SUBMIT ALERT',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildToggleItem(bool isSafety, String label, IconData icon) {
    final isSelected = _isSafetyIncident == isSafety;
    final Color activeColor = isSafety ? Colors.redAccent : const Color(0xFF2E7D32);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isSafetyIncident = isSafety;
          _selectedCategory = isSafety ? _safetyCategories[0] : _maintenanceCategories[0];
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [activeColor, activeColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black26),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton({required VoidCallback onTap, required IconData icon, required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
