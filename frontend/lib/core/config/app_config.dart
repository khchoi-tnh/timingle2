import 'package:flutter/foundation.dart';

/// 앱 설정 클래스
/// 환경변수 기반 설정을 관리합니다.
///
/// 빌드 시 --dart-define으로 값을 주입합니다:
/// ```bash
/// flutter build apk --dart-define=API_BASE_URL=https://api.timingle.com
/// ```
class AppConfig {
  AppConfig._();

  /// API 기본 URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// WebSocket URL
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  /// 앱 환경 (development, staging, production)
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// 디버그 모드 여부
  static bool get isDebug => environment == 'development';

  /// 프로덕션 모드 여부
  static bool get isProduction => environment == 'production';

  /// Google OAuth Client ID (Android)
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
    defaultValue: '',
  );

  /// Google OAuth Client ID (iOS)
  static const String googleClientIdIos = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_IOS',
    defaultValue: '',
  );

  /// Google OAuth Client ID (Web)
  static const String googleClientIdWeb = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_WEB',
    defaultValue: '',
  );

  /// 앱 버전
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// 빌드 번호
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );

  /// 로그 레벨
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );

  /// API 타임아웃 (초)
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );

  /// 설정 정보 출력 (디버그용)
  static void printConfig() {
    if (!isDebug) return;

    debugPrint('=== App Config ===');
    debugPrint('Environment: $environment');
    debugPrint('API Base URL: $apiBaseUrl');
    debugPrint('WebSocket URL: $wsUrl');
    debugPrint('App Version: $appVersion ($buildNumber)');
    debugPrint('==================');
  }
}
