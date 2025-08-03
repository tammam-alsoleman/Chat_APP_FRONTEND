// lib/core/config.dart

/// An enumeration to define the different application environments.
enum Environment {
  /// Development environment, for local testing and debugging.
  development,

  /// Production environment, for the live app released to users.
  production,
}

/// A centralized configuration manager for the application.
///
/// This class holds environment-specific variables like API base URLs.
/// It must be initialized once at app startup by calling the [setup] method.
/// Implemented as a singleton to ensure a single configuration state.
class AppConfig {
  // Private constructor to prevent direct instantiation.
  AppConfig._();

  // Singleton instance.
  static final AppConfig instance = AppConfig._();

  /// The current environment of the application.
  late Environment environment;

  /// The base URL for all API requests.
  late String baseUrl;

  /// Sets up the configuration based on the provided environment.
  /// This method MUST be called once in `main.dart` before the app runs.
  void setup({required Environment env}) {
    environment = env;
    switch (env) {
      case Environment.development:
      // For the Android Emulator, 10.0.2.2 points to the host machine's localhost.
        baseUrl = 'http://192.168.96.22:5000';
        break;
      case Environment.production:
      // IMPORTANT: Replace this with your actual public domain when you go live.
        baseUrl = 'https://your-production-api-domain.com';
        break;
    }
  }
}