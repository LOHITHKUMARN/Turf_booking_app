class ApiConstants {
  // Configurable at build time via --dart-define=API_SERVER_URL=https://your-domain.com
  static const String serverUrl = String.fromEnvironment(
    'API_SERVER_URL',
    defaultValue: 'https://turf-booking-app-op86.onrender.com',
  );
  static const String baseUrl = '$serverUrl/api';
  
  static const String loginUrl = '$baseUrl/auth/login';
  static const String signupUrl = '$baseUrl/auth/signup';
  static const String myTurfsUrl = '$baseUrl/owner/turfs';
  static const String tournamentsUrl = '$baseUrl/tournaments';
  static const String myTournamentsUrl = '$baseUrl/tournaments/my';
  static const String adminPendingTournamentsUrl = '$baseUrl/tournaments/admin/pending';
  static const String staffMatchesUrl = '$baseUrl/tournaments/staff/matches';
  static const String discoveryTournamentsUrl = '$baseUrl/tournaments/discovery';

  static String getImageUrl(String path) => getFullUrl(path);

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverUrl$cleanPath';
  }
}
