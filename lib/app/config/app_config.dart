class AppConfig {
  AppConfig._();

  static const String githubRepoOwner = 'Mahfoud-Sa';
  static const String githubRepoName = 'bokrah';

  /// Base URL of backend API
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.bokrah.com');

  /// Base authentication route
  static const String authBaseRoute = '/api/auth';
}
