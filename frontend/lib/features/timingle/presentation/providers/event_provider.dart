import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/cancel_event.dart';
import '../../domain/usecases/confirm_event.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/get_event.dart';
import '../../domain/usecases/get_events.dart';

/// 이벤트 목록 상태
class EventsState {
  final bool isLoading;
  final List<Event> events;
  final String? errorMessage;
  final bool hasReachedEnd;
  final int currentPage;

  const EventsState({
    this.isLoading = false,
    this.events = const [],
    this.errorMessage,
    this.hasReachedEnd = false,
    this.currentPage = 1,
  });

  EventsState copyWith({
    bool? isLoading,
    List<Event>? events,
    String? errorMessage,
    bool? hasReachedEnd,
    int? currentPage,
  }) {
    return EventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      errorMessage: errorMessage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// EventRemoteDataSource Provider
final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventRemoteDataSourceImpl(apiClient);
});

/// EventRepository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final remoteDataSource = ref.watch(eventRemoteDataSourceProvider);
  return EventRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// UseCase Providers
final getEventsUseCaseProvider = Provider<GetEvents>((ref) {
  return GetEvents(ref.watch(eventRepositoryProvider));
});

final getEventUseCaseProvider = Provider<GetEvent>((ref) {
  return GetEvent(ref.watch(eventRepositoryProvider));
});

final createEventUseCaseProvider = Provider<CreateEvent>((ref) {
  return CreateEvent(ref.watch(eventRepositoryProvider));
});

final confirmEventUseCaseProvider = Provider<ConfirmEvent>((ref) {
  return ConfirmEvent(ref.watch(eventRepositoryProvider));
});

final cancelEventUseCaseProvider = Provider<CancelEvent>((ref) {
  return CancelEvent(ref.watch(eventRepositoryProvider));
});

/// Events StateNotifier
class EventsNotifier extends StateNotifier<EventsState> {
  final GetEvents _getEvents;
  final CreateEvent _createEvent;
  final ConfirmEvent _confirmEvent;
  final CancelEvent _cancelEvent;

  EventsNotifier({
    required GetEvents getEvents,
    required CreateEvent createEvent,
    required ConfirmEvent confirmEvent,
    required CancelEvent cancelEvent,
  })  : _getEvents = getEvents,
        _createEvent = createEvent,
        _confirmEvent = confirmEvent,
        _cancelEvent = cancelEvent,
        super(const EventsState());

  /// 이벤트 목록 조회 (초기 로드)
  Future<void> loadEvents({String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getEvents(
      GetEventsParams(status: status, page: 1, limit: 20),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (events) {
        state = state.copyWith(
          isLoading: false,
          events: events,
          currentPage: 1,
          hasReachedEnd: events.length < 20,
        );
      },
    );
  }

  /// 이벤트 목록 더 불러오기 (무한 스크롤)
  Future<void> loadMoreEvents({String? status}) async {
    if (state.isLoading || state.hasReachedEnd) return;

    state = state.copyWith(isLoading: true);

    final nextPage = state.currentPage + 1;
    final result = await _getEvents(
      GetEventsParams(status: status, page: nextPage, limit: 20),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (events) {
        state = state.copyWith(
          isLoading: false,
          events: [...state.events, ...events],
          currentPage: nextPage,
          hasReachedEnd: events.length < 20,
        );
      },
    );
  }

  /// 이벤트 새로고침
  Future<void> refreshEvents({String? status}) async {
    await loadEvents(status: status);
  }

  /// 이벤트 생성
  Future<Event?> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  }) async {
    final result = await _createEvent(
      CreateEventParams(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        participantIds: participantIds,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return null;
      },
      (event) {
        state = state.copyWith(
          events: [event, ...state.events],
        );
        return event;
      },
    );
  }

  /// 이벤트 확정
  Future<bool> confirmEvent(int eventId) async {
    final result = await _confirmEvent(
      ConfirmEventParams(eventId: eventId),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (updatedEvent) {
        final updatedEvents = state.events.map((e) {
          return e.id == eventId ? updatedEvent : e;
        }).toList();
        state = state.copyWith(events: updatedEvents);
        return true;
      },
    );
  }

  /// 이벤트 취소
  Future<bool> cancelEvent(int eventId) async {
    final result = await _cancelEvent(
      CancelEventParams(eventId: eventId),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        final updatedEvents = state.events.where((e) => e.id != eventId).toList();
        state = state.copyWith(events: updatedEvents);
        return true;
      },
    );
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Events StateNotifier Provider
final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(
    getEvents: ref.watch(getEventsUseCaseProvider),
    createEvent: ref.watch(createEventUseCaseProvider),
    confirmEvent: ref.watch(confirmEventUseCaseProvider),
    cancelEvent: ref.watch(cancelEventUseCaseProvider),
  );
});

/// 단일 이벤트 조회 Provider (FutureProvider)
final eventDetailProvider = FutureProvider.family<Event?, int>((ref, id) async {
  final getEvent = ref.watch(getEventUseCaseProvider);
  final result = await getEvent(GetEventParams(id: id));
  return result.fold(
    (failure) => null,
    (event) => event,
  );
});
