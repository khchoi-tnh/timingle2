import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/timingle/domain/entities/event.dart';
import 'package:frontend/features/timingle/domain/repositories/event_repository.dart';
import 'package:frontend/features/timingle/domain/usecases/cancel_event.dart';
import 'package:frontend/features/timingle/domain/usecases/confirm_event.dart';
import 'package:frontend/features/timingle/domain/usecases/create_event.dart';
import 'package:frontend/features/timingle/domain/usecases/get_event.dart';
import 'package:frontend/features/timingle/domain/usecases/get_events.dart';

// Helper to create test events
Event createTestEvent({
  int id = 1,
  String title = 'Test Event',
  String status = 'PROPOSED',
}) {
  return Event(
    id: id,
    title: title,
    startTime: DateTime(2024, 1, 1, 10, 0),
    endTime: DateTime(2024, 1, 1, 12, 0),
    status: status,
    creatorId: 1,
    createdAt: DateTime(2024, 1, 1),
  );
}

// Mock Repository
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
    return getEventsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, Event>> getEvent(int id) async {
    return getEventResult ?? Left(const NotFoundFailure(message: 'Not found'));
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
    return createEventResult ?? Left(const ServerFailure(message: 'Not configured'));
  }

  @override
  Future<Either<Failure, Event>> confirmEvent(int eventId) async {
    return confirmEventResult ?? Left(const ServerFailure(message: 'Not configured'));
  }

  @override
  Future<Either<Failure, void>> cancelEvent(int eventId) async {
    return cancelEventResult ?? const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
  });

  group('GetEvents', () {
    late GetEvents useCase;

    setUp(() {
      useCase = GetEvents(mockRepository);
    });

    test('should return list of events on success', () async {
      final events = [
        createTestEvent(id: 1, title: 'Event 1'),
        createTestEvent(id: 2, title: 'Event 2'),
      ];
      mockRepository.getEventsResult = Right(events);

      final result = await useCase(const GetEventsParams());

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) {
          expect(data.length, 2);
          expect(data[0].title, 'Event 1');
        },
      );
    });

    test('should return empty list when no events', () async {
      mockRepository.getEventsResult = const Right([]);

      final result = await useCase(const GetEventsParams());

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) => expect(data, isEmpty),
      );
    });

    test('should filter by status', () async {
      final events = [createTestEvent(status: 'CONFIRMED')];
      mockRepository.getEventsResult = Right(events);

      final result = await useCase(const GetEventsParams(status: 'CONFIRMED'));

      expect(result.isRight(), isTrue);
    });
  });

  group('GetEvent', () {
    late GetEvent useCase;

    setUp(() {
      useCase = GetEvent(mockRepository);
    });

    test('should return event on success', () async {
      final event = createTestEvent(id: 1, title: 'My Event');
      mockRepository.getEventResult = Right(event);

      final result = await useCase(const GetEventParams(id: 1));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) {
          expect(data.id, 1);
          expect(data.title, 'My Event');
        },
      );
    });

    test('should return NotFoundFailure when event not found', () async {
      mockRepository.getEventResult = const Left(
        NotFoundFailure(message: 'Event not found'),
      );

      final result = await useCase(const GetEventParams(id: 999));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<NotFoundFailure>());
        },
        (data) => fail('Expected failure'),
      );
    });
  });

  group('CreateEvent', () {
    late CreateEvent useCase;

    setUp(() {
      useCase = CreateEvent(mockRepository);
    });

    test('should create and return event on success', () async {
      final event = createTestEvent(id: 1, title: 'New Event');
      mockRepository.createEventResult = Right(event);

      final result = await useCase(CreateEventParams(
        title: 'New Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 12, 0),
      ));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) {
          expect(data.title, 'New Event');
          expect(data.status, 'PROPOSED');
        },
      );
    });

    test('should return failure when creation fails', () async {
      mockRepository.createEventResult = const Left(
        ServerFailure(message: 'Failed to create'),
      );

      final result = await useCase(CreateEventParams(
        title: 'New Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 12, 0),
      ));

      expect(result.isLeft(), isTrue);
    });
  });

  group('ConfirmEvent', () {
    late ConfirmEvent useCase;

    setUp(() {
      useCase = ConfirmEvent(mockRepository);
    });

    test('should return confirmed event on success', () async {
      final event = createTestEvent(id: 1, status: 'CONFIRMED');
      mockRepository.confirmEventResult = Right(event);

      final result = await useCase(const ConfirmEventParams(eventId: 1));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) {
          expect(data.status, 'CONFIRMED');
        },
      );
    });

    test('should return failure when confirm fails', () async {
      mockRepository.confirmEventResult = const Left(
        ServerFailure(message: 'Cannot confirm'),
      );

      final result = await useCase(const ConfirmEventParams(eventId: 1));

      expect(result.isLeft(), isTrue);
    });
  });

  group('CancelEvent', () {
    late CancelEvent useCase;

    setUp(() {
      useCase = CancelEvent(mockRepository);
    });

    test('should return success on cancel', () async {
      mockRepository.cancelEventResult = const Right(null);

      final result = await useCase(const CancelEventParams(eventId: 1));

      expect(result.isRight(), isTrue);
    });

    test('should return failure when cancel fails', () async {
      mockRepository.cancelEventResult = const Left(
        ServerFailure(message: 'Cannot cancel'),
      );

      final result = await useCase(const CancelEventParams(eventId: 1));

      expect(result.isLeft(), isTrue);
    });
  });
}
