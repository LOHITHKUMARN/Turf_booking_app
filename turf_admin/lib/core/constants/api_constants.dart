class ApiConstants {
  // Configurable at build time via --dart-define=API_BASE_URL=https://your-domain.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://turf-booking-app-op86.onrender.com/api',
  );
  
  static const String loginUrl = '$baseUrl/auth/login';
  static const String signupUrl = '$baseUrl/auth/signup';
  static const String turfsUrl = '$baseUrl/admin/turfs';
  static const String usersUrl = '$baseUrl/admin/users';
  static const String statsUrl = '$baseUrl/admin/stats';
  static const String turfStatusUrl = '$baseUrl/admin/turf/status';
  static const String userStatusUrl = '$baseUrl/admin/user/status';
  static const String deleteUserUrl = '$baseUrl/admin/user';
  static const String auditLogsUrl = '$baseUrl/admin/audit-logs';

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final String serverRoot = baseUrl.split('/api')[0];
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverRoot$cleanPath';
  }
}
