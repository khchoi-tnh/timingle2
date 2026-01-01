/// 앱 전반에서 사용하는 상수
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'timingle';
  static const String appTagline = '약속이 대화가 되는 앱';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userPhoneKey = 'user_phone';
  static const String userNameKey = 'user_name';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Event Status
  static const String statusProposed = 'PROPOSED';
  static const String statusConfirmed = 'CONFIRMED';
  static const String statusCanceled = 'CANCELED';
  static const String statusDone = 'DONE';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeSystem = 'system';
  static const String messageTypeImage = 'image';

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;

  // WebSocket
  static const int wsReconnectDelay = 3000; // 3초
  static const int wsMaxReconnectAttempts = 5;

  // Animation
  static const int animationDuration = 300; // ms
}
