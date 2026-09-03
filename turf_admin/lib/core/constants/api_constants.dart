class ApiConstants {
  // Configurable at build time via --dart-define=API_BASE_URL=https://your-domain.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5005/api',
  );
  
  static const String loginUrl = '$baseUrl/auth/login';
  static const String signupUrl = '$baseUrl/auth/signup';
  static const String turfsUrl = '$baseUrl/admin/turfs';
  static const String usersUrl = '$baseUrl/admin/users';
  static const String statsUrl = '$baseUrl/admin/stats';
  static const String payoutStatsUrl = '$baseUrl/admin/payouts/stats';
  static const String pendingTournamentsUrl = '$baseUrl/tournaments/admin/pending';
  static const String approveTournamentUrl = '$baseUrl/tournaments/admin/approve'; 
  static const String allTournamentsUrl = '$baseUrl/tournaments';
  static const String turfStatusUrl = '$baseUrl/admin/turf/status';
  static const String userStatusUrl = '$baseUrl/admin/user/status';
  static const String deleteUserUrl = '$baseUrl/admin/user';

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final String serverRoot = baseUrl.split('/api')[0];
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverRoot$cleanPath';
  }
}
