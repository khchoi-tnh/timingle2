/// 빌드 환경별 설정
///
/// 사용 예시:
/// ```dart
/// final config = BuildConfig.forEnvironment('production');
/// print(config.apiBaseUrl);
/// ```
class BuildConfig {
  final String name;
  final String apiBaseUrl;
  final String wsUrl;
  final bool enableLogging;
  final bool enableCrashlytics;

  const BuildConfig({
    required this.name,
    required this.apiBaseUrl,
    required this.wsUrl,
    this.enableLogging = true,
    this.enableCrashlytics = false,
  });

  /// Development 환경
  static const development = BuildConfig(
    name: 'development',
    apiBaseUrl: 'http://localhost:8080',
    wsUrl: 'ws://localhost:8080/ws',
    enableLogging: true,
    enableCrashlytics: false,
  );

  /// Staging 환경
  static const staging = BuildConfig(
    name: 'staging',
    apiBaseUrl: 'https://staging-api.timingle.com',
    wsUrl: 'wss://staging-api.timingle.com/ws',
    enableLogging: true,
    enableCrashlytics: true,
  );

  /// Production 환경
  static const production = BuildConfig(
    name: 'production',
    apiBaseUrl: 'https://api.timingle.com',
    wsUrl: 'wss://api.timingle.com/ws',
    enableLogging: false,
    enableCrashlytics: true,
  );

  /// 환경 이름으로 설정 가져오기
  static BuildConfig forEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'production':
      case 'prod':
        return production;
      case 'staging':
      case 'stage':
        return staging;
      case 'development':
      case 'dev':
      default:
        return development;
    }
  }
}
