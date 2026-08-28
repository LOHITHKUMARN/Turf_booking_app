import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/constants/api_constants.dart';

class TournamentProvider with ChangeNotifier {
  List<Tournament> _tournaments = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Tournament> get tournaments => _tournaments;
  bool get isLoading => _isLoading;

  bool _isSocketInitialized = false;

  void initSocketListeners() {
    if (_isSocketInitialized) return;
    print('TournamentProvider: Initializing Socket Listeners');
    _isSocketInitialized = true;
    SocketService().on('team_status_updated', (data) {
      print('TournamentProvider: Team status updated: $data');
      // Refresh tournaments to get new status
      fetchPublicTournaments();
    });
  }

  Future<void> fetchPublicTournaments({String? sport, String? city}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String url = ApiConstants.discoveryTournamentsUrl;
      List<String> params = [];
      if (sport != null) params.add('sport=$sport');
      if (city != null) params.add('city=$city');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tournaments = data.map((json) => Tournament.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching tournaments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> registerTeam(String tournamentId, String teamName, List<String> members) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        ApiConstants.registerTeamUrl,
        {
          'tournamentId': tournamentId,
          'name': teamName,
          'members': members,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error registering team: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
