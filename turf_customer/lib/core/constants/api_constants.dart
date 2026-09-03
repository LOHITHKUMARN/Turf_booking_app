class ApiConstants {
  // Configurable at build time via --dart-define=API_BASE_URL=https://your-domain.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5005/api',
  );
  static const String tournamentsUrl = '$baseUrl/tournaments';
  static const String discoveryTournamentsUrl = '$baseUrl/tournaments/discovery';
  static const String registerTeamUrl = '$baseUrl/tournaments/register';
  static const String joinTeamUrl = '$baseUrl/tournaments/teams/join';

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Remove /api from baseUrl to get the server root
    final String serverRoot = baseUrl.split('/api')[0];
    // Ensure path starts with /
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverRoot$cleanPath';
  }
}
