class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:5005/api';
  static const String reportIncidentUrl = '$baseUrl/staff/incident';
  static const String staffMatchesUrl = '$baseUrl/tournaments/staff/matches';
  static const String updateScoreUrl = '$baseUrl/tournaments/matches'; // + /:matchId/score

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final String serverRoot = baseUrl.split('/api')[0];
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverRoot$cleanPath';
  }
}
