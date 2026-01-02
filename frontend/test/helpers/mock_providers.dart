import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/auth/domain/entities/auth_tokens.dart';
import 'package:frontend/features/auth/domain/entities/user.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/get_current_user.dart';
import 'package:frontend/features/auth/domain/usecases/logout.dart';
import 'package:frontend/features/auth/domain/usecases/register_with_phone.dart';
import 'package:frontend/features/auth/domain/usecases/try_auto_login.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/timingle/domain/entities/event.dart';
import 'package:frontend/features/timingle/domain/repositories/event_repository.dart';
import 'package:frontend/features/timingle/domain/usecases/cancel_event.dart';
import 'package:frontend/features/timingle/domain/usecases/confirm_event.dart';
import 'package:frontend/features/timingle/domain/usecases/create_event.dart';
import 'package:frontend/features/timingle/domain/usecases/get_events.dart';
import 'package:frontend/features/timingle/presentation/providers/event_provider.dart';

import 'test_helpers.dart';

/// Mock implementations for testing with Riverpod

// ==================== Mock Auth Repository ====================

class MockAuthRepository implements AuthRepository {
  Either<Failure, (User, AuthTokens)>? registerResult;
  Either<Failure, (User, AuthTokens)>? loginResult;
  Either<Failure, User>? getCurrentUserResult;
  Either<Failure, User>? tryAutoLoginResult;

  @override
  Future<Either<Failure, (User, AuthTokens)>> registerWithPhone({
    required String phone,
    required String name,
  }) async {
    return registerResult ??
        Right((createTestUser(phone: phone, name: name), createTestTokens()));
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return getCurrentUserResult ?? Right(createTestUser());
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> tryAutoLogin() async {
    return tryAutoLoginResult ?? const Left(AuthFailure(message: 'No token'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ==================== Mock Event Repository ====================

class MockEventRepository implements EventRepository {
  Either<Failure, List<Event>>? getEventsResult;
  Either<Failure, Event>? getEventResult;
  Either<Failure, Event>? createEventResult;
  Either<Failure, Event>? confirmEventResult;
  Either<Failure, void>? cancelEventResult;

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return getEventsResult ?? Right(createTestEventList());
  }

  @override
  Future<Either<Failure, Event>> getEvent(int id) async {
    return getEventResult ?? Right(createTestEvent(id: id));
  }

  @override
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  }) async {
    return createEventResult ?? Right(createTestEvent(title: title));
  }

  @override
  Future<Either<Failure, Event>> confirmEvent(int eventId) async {
    return confirmEventResult ??
        Right(createTestEvent(id: eventId, status: 'CONFIRMED'));
  }

  @override
  Future<Either<Failure, void>> cancelEvent(int eventId) async {
    return cancelEventResult ?? const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ==================== Mock UseCases ====================

class MockRegisterWithPhone implements RegisterWithPhone {
  Either<Failure, (User, AuthTokens)>? result;

  @override
  Future<Either<Failure, (User, AuthTokens)>> call(
      RegisterWithPhoneParams params) async {
    return result ??
        Right((
          createTestUser(phone: params.phone, name: params.name),
          createTestTokens()
        ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLogout implements Logout {
  bool wasCalled = false;

  @override
  Future<Either<Failure, void>> call() async {
    wasCalled = true;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetCurrentUser implements GetCurrentUser {
  Either<Failure, User>? result;

  @override
  Future<Either<Failure, User>> call() async {
    return result ?? Right(createTestUser());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTryAutoLogin implements TryAutoLogin {
  Either<Failure, User>? result;

  @override
  Future<Either<Failure, User>> call() async {
    return result ?? const Left(AuthFailure(message: 'No token'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetEvents implements GetEvents {
  Either<Failure, List<Event>>? result;

  @override
  Future<Either<Failure, List<Event>>> call(GetEventsParams params) async {
    return result ?? Right(createTestEventList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCreateEvent implements CreateEvent {
  Either<Failure, Event>? result;

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) async {
    return result ?? Right(createTestEvent(title: params.title));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConfirmEvent implements ConfirmEvent {
  Either<Failure, Event>? result;

  @override
  Future<Either<Failure, Event>> call(ConfirmEventParams params) async {
    return result ??
        Right(createTestEvent(id: params.eventId, status: 'CONFIRMED'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCancelEvent implements CancelEvent {
  Either<Failure, void>? result;

  @override
  Future<Either<Failure, void>> call(CancelEventParams params) async {
    return result ?? const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ==================== Provider Overrides ====================

/// Creates provider overrides for auth testing
List<Override> createAuthProviderOverrides({
  MockRegisterWithPhone? registerWithPhone,
  MockLogout? logout,
  MockGetCurrentUser? getCurrentUser,
  MockTryAutoLogin? tryAutoLogin,
}) {
  final mockRegister = registerWithPhone ?? MockRegisterWithPhone();
  final mockLogout = logout ?? MockLogout();
  final mockGetCurrentUser = getCurrentUser ?? MockGetCurrentUser();
  final mockTryAutoLogin = tryAutoLogin ?? MockTryAutoLogin();

  return [
    authProvider.overrideWith((ref) {
      return AuthNotifier(
        registerWithPhone: mockRegister,
        logout: mockLogout,
        getCurrentUser: mockGetCurrentUser,
        tryAutoLogin: mockTryAutoLogin,
      );
    }),
  ];
}

/// Creates provider overrides for events testing
List<Override> createEventsProviderOverrides({
  MockGetEvents? getEvents,
  MockCreateEvent? createEvent,
  MockConfirmEvent? confirmEvent,
  MockCancelEvent? cancelEvent,
}) {
  final mockGetEvents = getEvents ?? MockGetEvents();
  final mockCreateEvent = createEvent ?? MockCreateEvent();
  final mockConfirmEvent = confirmEvent ?? MockConfirmEvent();
  final mockCancelEvent = cancelEvent ?? MockCancelEvent();

  return [
    eventsProvider.overrideWith((ref) {
      return EventsNotifier(
        getEvents: mockGetEvents,
        createEvent: mockCreateEvent,
        confirmEvent: mockConfirmEvent,
        cancelEvent: mockCancelEvent,
      );
    }),
  ];
}

/// Creates combined provider overrides for full app testing
List<Override> createAllProviderOverrides({
  MockRegisterWithPhone? registerWithPhone,
  MockLogout? logout,
  MockGetCurrentUser? getCurrentUser,
  MockTryAutoLogin? tryAutoLogin,
  MockGetEvents? getEvents,
  MockCreateEvent? createEvent,
  MockConfirmEvent? confirmEvent,
  MockCancelEvent? cancelEvent,
}) {
  return [
    ...createAuthProviderOverrides(
      registerWithPhone: registerWithPhone,
      logout: logout,
      getCurrentUser: getCurrentUser,
      tryAutoLogin: tryAutoLogin,
    ),
    ...createEventsProviderOverrides(
      getEvents: getEvents,
      createEvent: createEvent,
      confirmEvent: confirmEvent,
      cancelEvent: cancelEvent,
    ),
  ];
}
