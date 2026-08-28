import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class TournamentProvider with ChangeNotifier {
  List<Tournament> _pendingTournaments = [];
  List<Tournament> _allTournaments = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Tournament> get pendingTournaments => _pendingTournaments;
  List<Tournament> get allTournaments => _allTournaments;
  bool get isLoading => _isLoading;

  Future<void> fetchPendingTournaments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.pendingTournamentsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _pendingTournaments = data.map((json) => Tournament.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching pending tournaments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllTournaments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.allTournamentsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _allTournaments = data.map((json) => Tournament.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching all tournaments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveTournament(String id, String status, {String? adminNotes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.approveTournamentUrl}/$id',
        {
          'status': status,
          'adminNotes': adminNotes ?? ''
        },
      );
      if (response.statusCode == 200) {
        await fetchPendingTournaments();
        return true;
      }
      return false;
    } catch (e) {
      print('Error approving tournament: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
