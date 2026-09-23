/// Build-time configuration, passed with `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// Base URL of `localstore-api` (host only, no `/v1`). The default reaches a
  /// host-machine API from the Android emulator; use
  /// `--dart-define=API_BASE_URL=...` otherwise.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Every demo route lives under `/v1`.
  static const apiPrefix = '/v1';
}
