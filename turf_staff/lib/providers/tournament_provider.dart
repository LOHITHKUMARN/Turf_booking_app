import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class TournamentProvider with ChangeNotifier {
  List<TournamentMatch> _staffMatches = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<TournamentMatch> get staffMatches => _staffMatches;
  bool get isLoading => _isLoading;

  Future<void> fetchStaffMatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.staffMatchesUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _staffMatches = data.map((json) => TournamentMatch.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMatchStatus(String matchId, String status, {int? score1, int? score2}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> body = {'status': status};
      if (score1 != null) body['score1'] = score1;
      if (score2 != null) body['score2'] = score2;

      final response = await _apiService.put(
        '${ApiConstants.updateScoreUrl}/$matchId/status',
        body,
      );
      if (response.statusCode == 200) {
        await fetchStaffMatches();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating match status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMatchScore(String matchId, int score1, int score2, {String? winnerId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.updateScoreUrl}/$matchId/score',
        {
          'score1': score1,
          'score2': score2,
          'winnerId': winnerId,
          'status': 'completed'
        },
      );
      if (response.statusCode == 200) {
        await fetchStaffMatches();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating score: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
