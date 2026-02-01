import 'dart:io';

/// API 관련 상수
class ApiConstants {
  ApiConstants._();

  // Base URLs - Android Emulator uses 10.0.2.2 to access host machine
  static String get _host {
    // Android Emulator: 10.0.2.2, iOS Simulator/Real device: localhost
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:8080';
  static const String apiVersion = '/api/v1';
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // WebSocket
  static String get wsBaseUrl => 'ws://$_host:8080';
  static String get wsEndpoint => '$wsBaseUrl$apiVersion/ws';

  // Timeout (milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Auth Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authGoogle = '/auth/google';
  static const String authGoogleCalendar = '/auth/google/calendar';

  // Calendar Endpoints
  static const String calendarStatus = '/calendar/status';
  static const String calendarEvents = '/calendar/events';
  static String calendarSync(int eventId) => '/calendar/sync/$eventId';

  // User Endpoints
  static const String usersMe = '/users/me';
  static const String usersSearch = '/users/search';

  // Event Endpoints
  static const String events = '/events';
  static String eventById(int id) => '/events/$id';
  static String eventConfirm(int id) => '/events/$id/confirm';
  static String eventMessages(int id) => '/events/$id/messages';

  // Open Slots Endpoints
  static const String openSlots = '/open-slots';
  static String openSlotBook(int id) => '/open-slots/$id/book';

  // Health Check
  static const String health = '/health';
}
