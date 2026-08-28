import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../providers/turf_provider.dart';
import '../../../core/constants/locations.dart';

import '../../../models/turf_model.dart';

class AddTurfScreen extends StatefulWidget {
  final Turf? turf;
  
  const AddTurfScreen({Key? key, this.turf}) : super(key: key);

  @override
  _AddTurfScreenState createState() => _AddTurfScreenState();
}

class _AddTurfScreenState extends State<AddTurfScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _upiController = TextEditingController();
  final _taxController = TextEditingController();
  File? _selectedImage;
  final _picker = ImagePicker();
  
  final List<String> _selectedSports = [];
  final List<String> _selectedAmenities = [];
  final List<String> _grounds = [];
  final _groundController = TextEditingController();

  final List<String> _availableSports = ['Football', 'Cricket', 'Tennis', 'Badminton'];
  final List<String> _availableAmenities = ['Changing Room', 'Parking', 'Washroom', 'Floodlights', 'Drinking Water'];
  final List<String> _turfTypes = ['indoor', 'outdoor', 'both'];
  String _selectedTurfType = 'both';

  @override
  void initState() {
    super.initState();
    if (widget.turf != null) {
      _nameController.text = widget.turf!.name;
      _cityController.text = widget.turf!.city;
      _areaController.text = widget.turf!.area;
      _selectedSports.addAll(widget.turf!.sports);
      _selectedAmenities.addAll(widget.turf!.amenities);
      _grounds.addAll(widget.turf!.grounds);
      _upiController.text = widget.turf!.upiId;
      _taxController.text = widget.turf!.taxPercentage.toString();
      _selectedTurfType = widget.turf!.turfType;
      // We don't initialize _selectedImage because it's for picking new files.
      // Remote images are handled separately in _submit if no new image is picked.
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showCityPicker() {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final List<String> filteredLocations = Locations.indianCities
              .where((loc) => loc.toLowerCase().contains(searchQuery.toLowerCase()) && loc != 'All Locations')
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select City',
                      style: GoogleFonts.poppins(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setModalState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00A86B)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredLocations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        filteredLocations[index],
                        style: GoogleFonts.poppins(
                          color: _cityController.text == filteredLocations[index] ? const Color(0xFF00A86B) : Colors.black87,
                          fontWeight: _cityController.text == filteredLocations[index] ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: _cityController.text == filteredLocations[index] ? const Icon(Icons.check_circle, color: Color(0xFF00A86B)) : null,
                      onTap: () {
                        setState(() {
                          _cityController.text = filteredLocations[index];
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.isEmpty || _cityController.text.isEmpty || _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    String? imageUrl;
    List<String> images = widget.turf?.images ?? [];
    if (_selectedImage != null) {
      imageUrl = await Provider.of<TurfProvider>(context, listen: false).uploadImage(_selectedImage!.path);
      if (imageUrl != null) {
        images = [imageUrl];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Continuing with existing/no image...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final turfProvider = Provider.of<TurfProvider>(context, listen: false);
    final bool success;

    if (widget.turf != null) {
      success = await turfProvider.updateTurf(
        id: widget.turf!.id,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        sports: _selectedSports,
        amenities: _selectedAmenities,
        images: images,
        grounds: _grounds,
        upiId: _upiController.text.trim(),
        taxPercentage: double.tryParse(_taxController.text) ?? 0.0,
        turfType: _selectedTurfType,
      );
    } else {
      success = await turfProvider.addTurf(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        sports: _selectedSports,
        amenities: _selectedAmenities,
        images: images,
        grounds: _grounds,
        upiId: _upiController.text.trim(),
        taxPercentage: double.tryParse(_taxController.text) ?? 0.0,
        turfType: _selectedTurfType,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.turf != null ? 'Turf updated successfully!' : 'Turf added successfully! Pending approval.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.turf != null ? 'Failed to update turf.' : 'Failed to add turf.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<TurfProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.turf != null ? 'Edit Turf' : 'Add New Turf'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turf Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Turf Name',
                prefixIcon: Icon(Icons.stadium_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Turf Image',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showCityPicker,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      prefixIcon: Icon(Icons.map_outlined, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (optional)',
                      hintText: 'user@bank',
                      prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      prefixIcon: Icon(Icons.percent_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedTurfType,
              decoration: const InputDecoration(
                labelText: 'Turf Type',
                prefixIcon: Icon(Icons.roofing_outlined, size: 20),
              ),
              items: _turfTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTurfType = newValue!;
                });
              },
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Grounds (Sub-units)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groundController,
                    decoration: const InputDecoration(
                      labelText: 'Ground Name',
                      hintText: 'e.g. Ground A, Court 1',
                      prefixIcon: Icon(Icons.stadium, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    if (_groundController.text.trim().isNotEmpty) {
                      setState(() {
                        _grounds.add(_groundController.text.trim());
                        _groundController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle, color: Color(0xFF00A86B), size: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _grounds.map((g) => Chip(
                label: Text(g),
                onDeleted: () => setState(() => _grounds.remove(g)),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
                labelStyle: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )).toList(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Sports Provided'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableSports.map((sport) {
                final isSelected = _selectedSports.contains(sport);
                return _buildCustomChip(
                  sport,
                  isSelected,
                  (val) {
                    setState(() {
                      val ? _selectedSports.add(sport) : _selectedSports.remove(sport);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Amenities'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return _buildCustomChip(
                  amenity,
                  isSelected,
                  (val) {
                    setState(() {
                      val ? _selectedAmenities.add(amenity) : _selectedAmenities.remove(amenity);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(widget.turf != null ? 'UPDATE TURF' : 'ADD TURF'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildCustomChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      elevation: 0,
      pressElevation: 0,
      backgroundColor: const Color(0xFFF1F3F5),
      selectedColor: const Color(0xFF00A86B).withOpacity(0.1),
      checkmarkColor: const Color(0xFF00A86B),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00A86B) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF00A86B).withOpacity(0.2) : Colors.transparent,
        ),
      ),
    );
  }
}
