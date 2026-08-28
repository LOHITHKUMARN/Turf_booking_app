class ApiConstants {
  static const String serverUrl = 'http://10.0.2.2:5005';
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
