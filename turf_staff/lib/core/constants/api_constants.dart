class ApiConstants {
  // Configurable at build time via --dart-define=API_BASE_URL=https://your-domain.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://turf-booking-app-op86.onrender.com/api',
  );
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
