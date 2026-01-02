import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/auth/domain/entities/auth_tokens.dart';
import 'package:frontend/features/auth/domain/entities/user.dart';
import 'package:frontend/features/timingle/domain/entities/event.dart';

/// Test helper utilities for creating mock data and widgets

// ==================== User Helpers ====================

/// Creates a test user with default values
User createTestUser({
  int id = 1,
  String phone = '01012345678',
  String name = 'Test User',
  String? email,
  String role = 'USER',
  DateTime? createdAt,
}) {
  return User(
    id: id,
    phone: phone,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

/// Creates test auth tokens
AuthTokens createTestTokens({
  String accessToken = 'test_access_token',
  String refreshToken = 'test_refresh_token',
}) {
  return AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}

// ==================== Event Helpers ====================

/// Creates a test event with default values
Event createTestEvent({
  int id = 1,
  String title = 'Test Event',
  String? description,
  DateTime? startTime,
  DateTime? endTime,
  String? location,
  String status = 'PROPOSED',
  int creatorId = 1,
  List<EventParticipant> participants = const [],
  int? unreadMessages,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Event(
    id: id,
    title: title,
    description: description,
    startTime: startTime ?? now.add(const Duration(hours: 24)),
    endTime: endTime ?? now.add(const Duration(hours: 26)),
    location: location,
    status: status,
    creatorId: creatorId,
    participants: participants,
    unreadMessages: unreadMessages,
    createdAt: createdAt ?? now,
  );
}

/// Creates a test event participant
EventParticipant createTestParticipant({
  int id = 1,
  String name = 'Participant',
  String? displayName,
  String? profileImageUrl,
  bool confirmed = false,
}) {
  return EventParticipant(
    id: id,
    name: name,
    displayName: displayName,
    profileImageUrl: profileImageUrl,
    confirmed: confirmed,
  );
}

/// Creates a list of test events
List<Event> createTestEventList({int count = 5}) {
  return List.generate(
    count,
    (i) => createTestEvent(
      id: i + 1,
      title: 'Event ${i + 1}',
    ),
  );
}

// ==================== Failure Helpers ====================

/// Creates a server failure
Failure createServerFailure({String message = 'Server error'}) {
  return ServerFailure(message: message);
}

/// Creates a network failure
Failure createNetworkFailure({String message = '네트워크 연결을 확인해주세요'}) {
  return NetworkFailure(message: message);
}

/// Creates an auth failure
Failure createAuthFailure({String message = 'Unauthorized'}) {
  return AuthFailure(message: message);
}

/// Creates a not found failure
Failure createNotFoundFailure({String message = 'Not found'}) {
  return NotFoundFailure(message: message);
}

// ==================== Either Helpers ====================

/// Creates a successful Either result
Either<Failure, T> success<T>(T value) => Right(value);

/// Creates a failed Either result
Either<Failure, T> failure<T>(Failure fail) => Left(fail);

// ==================== Widget Helpers ====================

/// Wraps a widget with MaterialApp for testing
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

/// Wraps a widget with ProviderScope and MaterialApp for testing
Widget wrapWithProviderScope(
  Widget child, {
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Wraps a widget with Scaffold for testing
Widget wrapWithScaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

// ==================== Mock Response Helpers ====================

/// Creates a mock paginated response
Map<String, dynamic> createPaginatedResponse<T>({
  required List<T> items,
  int page = 1,
  int limit = 20,
  int total = 100,
}) {
  return {
    'items': items,
    'page': page,
    'limit': limit,
    'total': total,
    'hasMore': page * limit < total,
  };
}

/// Creates a mock error response
Map<String, dynamic> createErrorResponse({
  String message = 'Error occurred',
  String? code,
  int? statusCode,
}) {
  return {
    'error': {
      'message': message,
      if (code != null) 'code': code,
      if (statusCode != null) 'statusCode': statusCode,
    },
  };
}

// ==================== Date Helpers ====================

/// Creates a DateTime for testing (fixed date)
DateTime createTestDateTime({
  int year = 2024,
  int month = 6,
  int day = 15,
  int hour = 14,
  int minute = 0,
}) {
  return DateTime(year, month, day, hour, minute);
}

/// Creates a future DateTime relative to now
DateTime createFutureDateTime({Duration offset = const Duration(days: 1)}) {
  return DateTime.now().add(offset);
}

/// Creates a past DateTime relative to now
DateTime createPastDateTime({Duration offset = const Duration(days: 1)}) {
  return DateTime.now().subtract(offset);
}
