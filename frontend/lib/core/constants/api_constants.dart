/// API 관련 상수
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // WebSocket
  static const String wsBaseUrl = 'ws://localhost:8080';
  static const String wsEndpoint = '$wsBaseUrl$apiVersion/ws';

  // Timeout (milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Auth Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

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
