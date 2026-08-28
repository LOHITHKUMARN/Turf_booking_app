import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/constants/api_constants.dart';

class TournamentProvider with ChangeNotifier {
  List<Tournament> _myTournaments = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Tournament> get myTournaments => _myTournaments;
  bool get isLoading => _isLoading;

  bool _isSocketInitialized = false;

  void initSocketListeners() {
    if (_isSocketInitialized) return;
    print('TournamentProvider: Initializing Socket Listeners');
    _isSocketInitialized = true;
    SocketService().on('new_registration', (data) {
      print('TournamentProvider: New registration received: $data');
      fetchMyTournaments();
    });
  }

  Future<void> fetchMyTournaments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.myTournamentsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myTournaments = data.map<Tournament>((json) => Tournament.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching my tournaments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTournament(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.tournamentsUrl, data);
      if (response.statusCode == 201) {
        await fetchMyTournaments();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating tournament: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTournament(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('${ApiConstants.tournamentsUrl}/$id', data);
      if (response.statusCode == 200) {
        await fetchMyTournaments();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating tournament: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TournamentTeam> _teams = [];
  List<TournamentTeam> get teams => _teams;

  Future<void> fetchTournamentTeams(String tournamentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.tournamentsUrl}/$tournamentId/teams');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _teams = data.map((json) => TournamentTeam.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching teams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTeamStatus(String teamId, String status) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.tournamentsUrl}/teams/$teamId/status',
        {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating team status: $e');
      return false;
    }
  }

  List<TournamentMatch> _matches = [];
  List<TournamentMatch> get matches => _matches;

  Future<void> fetchTournamentMatches(String tournamentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.tournamentsUrl}/$tournamentId/matches');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _matches = data.map((json) => TournamentMatch.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateFixtures(String tournamentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.tournamentsUrl}/$tournamentId/fixtures/generate',
        {},
      );
      if (response.statusCode == 200) {
        await fetchMyTournaments();
        await fetchTournamentMatches(tournamentId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error generating fixtures: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMatch(String tournamentId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('${ApiConstants.tournamentsUrl}/$tournamentId/matches', data);
      if (response.statusCode == 201) {
        await fetchTournamentMatches(tournamentId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating match: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMatch(String tournamentId, String matchId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('${ApiConstants.tournamentsUrl}/matches/$matchId', data);
      if (response.statusCode == 200) {
        await fetchTournamentMatches(tournamentId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating match: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMatch(String tournamentId, String matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.delete('${ApiConstants.tournamentsUrl}/matches/$matchId');
      if (response.statusCode == 200) {
        await fetchTournamentMatches(tournamentId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting match: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
