// Configuration file for the Shop Manager app.
// This file centralizes all configuration constants and environment variables.
//
// Usage:
// - Default production URL: https://shop-manager-backend-xe9d.onrender.com
// - Override with --dart-define=BACKEND_URL=https://your-custom-url.com
// - For development: flutter run --dart-define=BACKEND_URL=http://localhost:8000
//
// Important: Always use HTTPS in production to ensure secure communication.

/// The backend URL for API calls.
/// Uses String.fromEnvironment to allow runtime configuration via --dart-define.
/// Falls back to the deployed production URL on Render.
const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://shop-manager-backend-xe9d.onrender.com',
);

/// Validates the backend URL to prevent accidental use of local URLs in release builds.
/// Throws an exception if a local URL is detected in release mode.
void validateBackendUrl() {
  const isRelease = bool.fromEnvironment('dart.vm.product');
  if (isRelease &&
      (backendUrl.contains('localhost') ||
          backendUrl.contains('127.0.0.1') ||
          backendUrl.contains('10.0.2.2'))) {
    throw Exception('ERROR: Local backend URL detected in release build!\n'
        'Active URL: $backendUrl\n'
        'Please ensure you are using a production URL for release builds.\n'
        'Use: flutter build apk --dart-define=BACKEND_URL=https://your-production-url.com');
  }
}

/// Environment type for conditional logic (optional enhancement).
enum Environment { dev, prod }

/// Determines the current environment based on the backend URL.
Environment get currentEnvironment {
  if (backendUrl.contains('localhost') ||
      backendUrl.contains('127.0.0.1') ||
      backendUrl.contains('10.0.2.2')) {
    return Environment.dev;
  }
  return Environment.prod;
}

/// Timeout duration for HTTP requests (in seconds).
/// Increased for Render free tier cold starts.
const int httpTimeoutSeconds = 30;
