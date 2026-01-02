import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/timingle/domain/entities/event.dart';
import 'package:frontend/features/timingle/domain/usecases/cancel_event.dart';
import 'package:frontend/features/timingle/domain/usecases/confirm_event.dart';
import 'package:frontend/features/timingle/domain/usecases/create_event.dart';
import 'package:frontend/features/timingle/domain/usecases/get_events.dart';
import 'package:frontend/features/timingle/presentation/providers/event_provider.dart';

// Test helper to create Event
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

// Mock UseCases
class MockGetEvents implements GetEvents {
  Either<Failure, List<Event>>? result;

  @override
  Future<Either<Failure, List<Event>>> call(GetEventsParams params) async {
    return result ?? const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCreateEvent implements CreateEvent {
  Either<Failure, Event>? result;

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) async {
    return result ?? Left(const ServerFailure(message: 'Not configured'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConfirmEvent implements ConfirmEvent {
  Either<Failure, Event>? result;

  @override
  Future<Either<Failure, Event>> call(ConfirmEventParams params) async {
    return result ?? Left(const ServerFailure(message: 'Not configured'));
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

void main() {
  group('EventsState', () {
    test('initial state should have correct defaults', () {
      const state = EventsState();

      expect(state.isLoading, isFalse);
      expect(state.events, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.hasReachedEnd, isFalse);
      expect(state.currentPage, 1);
    });

    test('copyWith should update only specified fields', () {
      const state = EventsState();
      final events = [createTestEvent()];

      final newState = state.copyWith(
        isLoading: true,
        events: events,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.events, events);
      expect(newState.errorMessage, isNull);
    });

    test('copyWith should allow setting errorMessage to null', () {
      final state = const EventsState().copyWith(errorMessage: 'Error');
      expect(state.errorMessage, 'Error');

      final clearedState = state.copyWith(errorMessage: null);
      expect(clearedState.errorMessage, isNull);
    });
  });

  group('EventsNotifier', () {
    late MockGetEvents mockGetEvents;
    late MockCreateEvent mockCreateEvent;
    late MockConfirmEvent mockConfirmEvent;
    late MockCancelEvent mockCancelEvent;
    late EventsNotifier notifier;

    setUp(() {
      mockGetEvents = MockGetEvents();
      mockCreateEvent = MockCreateEvent();
      mockConfirmEvent = MockConfirmEvent();
      mockCancelEvent = MockCancelEvent();

      notifier = EventsNotifier(
        getEvents: mockGetEvents,
        createEvent: mockCreateEvent,
        confirmEvent: mockConfirmEvent,
        cancelEvent: mockCancelEvent,
      );
    });

    test('initial state should have empty events', () {
      expect(notifier.state.events, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    group('loadEvents', () {
      test('should load events successfully', () async {
        final events = [
          createTestEvent(id: 1, title: 'Event 1'),
          createTestEvent(id: 2, title: 'Event 2'),
        ];
        mockGetEvents.result = Right(events);

        await notifier.loadEvents();

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.events.length, 2);
        expect(notifier.state.events[0].title, 'Event 1');
        expect(notifier.state.currentPage, 1);
      });

      test('should set error on failure', () async {
        mockGetEvents.result = const Left(ServerFailure(message: 'Server error'));

        await notifier.loadEvents();

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.errorMessage, 'Server error');
      });

      test('should set hasReachedEnd when less than 20 events returned', () async {
        final events = List.generate(
          5,
          (i) => createTestEvent(id: i, title: 'Event $i'),
        );
        mockGetEvents.result = Right(events);

        await notifier.loadEvents();

        expect(notifier.state.hasReachedEnd, isTrue);
      });
    });

    group('loadMoreEvents', () {
      test('should append events to existing list', () async {
        // First load
        final firstEvents = List.generate(
          20,
          (i) => createTestEvent(id: i, title: 'Event $i'),
        );
        mockGetEvents.result = Right(firstEvents);
        await notifier.loadEvents();

        // Load more
        final moreEvents = List.generate(
          5,
          (i) => createTestEvent(id: i + 20, title: 'Event ${i + 20}'),
        );
        mockGetEvents.result = Right(moreEvents);
        await notifier.loadMoreEvents();

        expect(notifier.state.events.length, 25);
        expect(notifier.state.currentPage, 2);
        expect(notifier.state.hasReachedEnd, isTrue);
      });

      test('should not load if already loading', () async {
        // Start loading
        final events = List.generate(
          20,
          (i) => createTestEvent(id: i, title: 'Event $i'),
        );
        mockGetEvents.result = Right(events);
        await notifier.loadEvents();

        // Manually set loading state
        notifier.state = notifier.state.copyWith(isLoading: true);
        final currentLength = notifier.state.events.length;

        await notifier.loadMoreEvents();

        // Should not have changed (loading was blocked)
        expect(notifier.state.events.length, currentLength);
      });

      test('should not load if hasReachedEnd', () async {
        // Load with less than 20 events (sets hasReachedEnd)
        final events = List.generate(
          5,
          (i) => createTestEvent(id: i, title: 'Event $i'),
        );
        mockGetEvents.result = Right(events);
        await notifier.loadEvents();

        expect(notifier.state.hasReachedEnd, isTrue);

        await notifier.loadMoreEvents();

        // Should still be 5 events
        expect(notifier.state.events.length, 5);
        expect(notifier.state.currentPage, 1);
      });
    });

    group('createEvent', () {
      test('should add event to list on success', () async {
        final newEvent = createTestEvent(id: 1, title: 'New Event');
        mockCreateEvent.result = Right(newEvent);

        final result = await notifier.createEvent(
          title: 'New Event',
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 12, 0),
        );

        expect(result, isNotNull);
        expect(result?.title, 'New Event');
        expect(notifier.state.events.length, 1);
        expect(notifier.state.events[0].id, 1);
      });

      test('should return null on failure', () async {
        mockCreateEvent.result = const Left(ServerFailure(message: 'Failed'));

        final result = await notifier.createEvent(
          title: 'New Event',
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 12, 0),
        );

        expect(result, isNull);
        expect(notifier.state.errorMessage, 'Failed');
      });
    });

    group('confirmEvent', () {
      test('should update event status on success', () async {
        // First add an event
        final event = createTestEvent(id: 1, status: 'PROPOSED');
        mockGetEvents.result = Right([event]);
        await notifier.loadEvents();

        // Confirm the event
        final confirmedEvent = createTestEvent(id: 1, status: 'CONFIRMED');
        mockConfirmEvent.result = Right(confirmedEvent);

        final result = await notifier.confirmEvent(1);

        expect(result, isTrue);
        expect(notifier.state.events[0].status, 'CONFIRMED');
      });

      test('should return false on failure', () async {
        mockConfirmEvent.result = const Left(ServerFailure(message: 'Failed'));

        final result = await notifier.confirmEvent(1);

        expect(result, isFalse);
        expect(notifier.state.errorMessage, 'Failed');
      });
    });

    group('cancelEvent', () {
      test('should remove event from list on success', () async {
        // First add events
        final events = [
          createTestEvent(id: 1, title: 'Event 1'),
          createTestEvent(id: 2, title: 'Event 2'),
        ];
        mockGetEvents.result = Right(events);
        await notifier.loadEvents();
        expect(notifier.state.events.length, 2);

        // Cancel one event
        mockCancelEvent.result = const Right(null);
        final result = await notifier.cancelEvent(1);

        expect(result, isTrue);
        expect(notifier.state.events.length, 1);
        expect(notifier.state.events[0].id, 2);
      });

      test('should return false on failure', () async {
        mockCancelEvent.result = const Left(ServerFailure(message: 'Failed'));

        final result = await notifier.cancelEvent(1);

        expect(result, isFalse);
        expect(notifier.state.errorMessage, 'Failed');
      });
    });

    test('clearError should clear error message', () async {
      mockCreateEvent.result = const Left(ServerFailure(message: 'Error'));
      await notifier.createEvent(
        title: 'Test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      expect(notifier.state.errorMessage, 'Error');

      notifier.clearError();

      expect(notifier.state.errorMessage, isNull);
    });

    test('refreshEvents should reload events', () async {
      // Load initial events
      final events = [createTestEvent(id: 1)];
      mockGetEvents.result = Right(events);
      await notifier.loadEvents();
      expect(notifier.state.events.length, 1);

      // Refresh with new events
      final newEvents = [
        createTestEvent(id: 1),
        createTestEvent(id: 2),
      ];
      mockGetEvents.result = Right(newEvents);
      await notifier.refreshEvents();

      expect(notifier.state.events.length, 2);
      expect(notifier.state.currentPage, 1);
    });
  });
}
