/// Build-time configuration, passed with `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// Base URL of `localstore-api`. The default reaches a host-machine API from
  /// the Android emulator; use `--dart-define=API_BASE_URL=...` otherwise.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
