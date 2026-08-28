import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../../models/turf_model.dart';

class TurfProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Turf> _turfs = [];
  bool _isLoading = false;
  String _selectedLocation = 'Bengaluru';
  String _searchQuery = '';
  String _selectedTurfType = 'All'; // 'All' | 'indoor' | 'outdoor' | 'both'
  String _selectedSport = 'All';   // 'All' | any sport name

  TurfProvider() {
    _initLocation();
  }

  List<Turf> get turfs => _turfs;
  bool get isLoading => _isLoading;
  String get selectedLocation => _selectedLocation;
  String get searchQuery => _searchQuery;
  String get selectedTurfType => _selectedTurfType;
  String get selectedSport => _selectedSport;

  /// Unique list of sports across all loaded turfs
  List<String> get availableSports {
    final Set<String> sportsSet = {};
    for (final turf in _turfs) {
      sportsSet.addAll(turf.sports);
    }
    return sportsSet.toList()..sort();
  }

  Future<void> _initLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('selected_location');
    if (savedLocation != null) {
      _selectedLocation = savedLocation;
      notifyListeners();
    }
  }

  /// Filtered list applying: location → search → turfType → sport
  List<Turf> get filteredTurfs {
    List<Turf> result = _turfs;

    // Location filter
    if (_selectedLocation != 'All Locations') {
      result = result.where((turf) {
        return turf.city.toLowerCase().contains(_selectedLocation.toLowerCase()) ||
               turf.area.toLowerCase().contains(_selectedLocation.toLowerCase());
      }).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((turf) {
        return turf.name.toLowerCase().contains(query) ||
               turf.area.toLowerCase().contains(query) ||
               turf.city.toLowerCase().contains(query) ||
               turf.sports.any((s) => s.toLowerCase().contains(query));
      }).toList();
    }

    // Turf type filter
    if (_selectedTurfType != 'All') {
      result = result.where((turf) =>
          turf.turfType.toLowerCase() == _selectedTurfType.toLowerCase()).toList();
    }

    // Sport filter
    if (_selectedSport != 'All') {
      result = result.where((turf) =>
          turf.sports.any((s) => s.toLowerCase() == _selectedSport.toLowerCase())).toList();
    }

    return result;
  }

  void setLocation(String location) async {
    _selectedLocation = location;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_location', location);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTurfType(String type) {
    _selectedTurfType = type;
    notifyListeners();
  }

  void setSport(String sport) {
    _selectedSport = sport;
    notifyListeners();
  }

  void clearFilters() {
    _selectedTurfType = 'All';
    _selectedSport = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> fetchTurfs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/customer/turfs');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _turfs = data.map((item) => Turf.fromJson(item)).toList();
      }
    } catch (e) {
      print('Fetch turfs error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
