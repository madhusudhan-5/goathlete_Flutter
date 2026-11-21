class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '740629489616-c6j07tvj7gg7a6ulfpsu8tmptf151adu.apps.googleusercontent.com',
  );

  static const String webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://app.goathlete.com',
  );

  /// Backend origin without trailing slash, e.g. `https://api.goathlete.com`.
  static String get apiOrigin {
    var trimmed = _rawApiBaseUrl.trim();
    if (trimmed.endsWith('/api/')) {
      trimmed = trimmed.substring(0, trimmed.length - 5);
    } else if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Backend REST API base URL with trailing slash, e.g. `https://api.goathlete.com/api/`.
  static String get apiBaseUrl => '$apiOrigin/api/';

  /// Resolves relative media paths like `/media/avatars/pic.jpg` against [apiOrigin].
  static String? resolveMediaUrl(dynamic rawPath) {
    if (rawPath == null) return null;
    final path = rawPath.toString().trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$apiOrigin$path';
    }
    return '$apiOrigin/$path';
  }
}
