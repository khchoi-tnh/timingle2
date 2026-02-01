import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/token_storage.dart';
import '../../data/datasources/calendar_remote_datasource.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/usecases/get_calendar_events.dart';
import '../../domain/usecases/get_calendar_status.dart';
import '../../domain/usecases/login_with_calendar.dart';
import '../../domain/usecases/sync_event_to_calendar.dart';

/// Calendar 상태
enum CalendarStateStatus {
  initial,
  loading,
  success,
  error,
}

/// Calendar 상태 클래스
class CalendarState {
  final CalendarStateStatus status;
  final bool hasCalendarAccess;
  final List<CalendarEvent> events;
  final String? errorMessage;
  final bool isSyncing;

  const CalendarState({
    this.status = CalendarStateStatus.initial,
    this.hasCalendarAccess = false,
    this.events = const [],
    this.errorMessage,
    this.isSyncing = false,
  });

  CalendarState copyWith({
    CalendarStateStatus? status,
    bool? hasCalendarAccess,
    List<CalendarEvent>? events,
    String? errorMessage,
    bool? isSyncing,
  }) {
    return CalendarState(
      status: status ?? this.status,
      hasCalendarAccess: hasCalendarAccess ?? this.hasCalendarAccess,
      events: events ?? this.events,
      errorMessage: errorMessage,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  bool get isLoading => status == CalendarStateStatus.loading;
}

/// CalendarRemoteDataSource Provider
final calendarRemoteDataSourceProvider =
    Provider<CalendarRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarRemoteDataSourceImpl(apiClient);
});

/// CalendarRepository Provider
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final remoteDataSource = ref.watch(calendarRemoteDataSourceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  final wsClient = ref.watch(webSocketClientProvider);

  return CalendarRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
    apiClient: apiClient,
    wsClient: wsClient,
  );
});

/// UseCase Providers
final getCalendarStatusUseCaseProvider = Provider<GetCalendarStatus>((ref) {
  return GetCalendarStatus(ref.watch(calendarRepositoryProvider));
});

final getCalendarEventsUseCaseProvider = Provider<GetCalendarEvents>((ref) {
  return GetCalendarEvents(ref.watch(calendarRepositoryProvider));
});

final syncEventToCalendarUseCaseProvider = Provider<SyncEventToCalendar>((ref) {
  return SyncEventToCalendar(ref.watch(calendarRepositoryProvider));
});

final loginWithCalendarUseCaseProvider = Provider<LoginWithCalendar>((ref) {
  return LoginWithCalendar(ref.watch(calendarRepositoryProvider));
});

/// Calendar StateNotifier
class CalendarNotifier extends StateNotifier<CalendarState> {
  final GetCalendarStatus _getCalendarStatus;
  final GetCalendarEvents _getCalendarEvents;
  final SyncEventToCalendar _syncEventToCalendar;
  final LoginWithCalendar _loginWithCalendar;

  CalendarNotifier({
    required GetCalendarStatus getCalendarStatus,
    required GetCalendarEvents getCalendarEvents,
    required SyncEventToCalendar syncEventToCalendar,
    required LoginWithCalendar loginWithCalendar,
  })  : _getCalendarStatus = getCalendarStatus,
        _getCalendarEvents = getCalendarEvents,
        _syncEventToCalendar = syncEventToCalendar,
        _loginWithCalendar = loginWithCalendar,
        super(const CalendarState());

  /// Calendar 연동 상태 확인
  Future<void> checkCalendarStatus() async {
    state = state.copyWith(status: CalendarStateStatus.loading);

    final result = await _getCalendarStatus(const NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(
          status: CalendarStateStatus.error,
          errorMessage: failure.message,
          hasCalendarAccess: false,
        );
      },
      (calendarStatus) {
        state = state.copyWith(
          status: CalendarStateStatus.success,
          hasCalendarAccess: calendarStatus.hasCalendarAccess,
          errorMessage: null,
        );
      },
    );
  }

  /// Calendar 이벤트 조회
  Future<void> fetchCalendarEvents({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    state = state.copyWith(status: CalendarStateStatus.loading);

    final result = await _getCalendarEvents(
      GetCalendarEventsParams(startTime: startTime, endTime: endTime),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: CalendarStateStatus.error,
          errorMessage: failure.message,
        );
      },
      (events) {
        state = state.copyWith(
          status: CalendarStateStatus.success,
          events: events,
          errorMessage: null,
        );
      },
    );
  }

  /// timingle 이벤트를 Google Calendar에 동기화
  Future<SyncedCalendarEvent?> syncToCalendar(int eventId) async {
    state = state.copyWith(isSyncing: true);

    final result = await _syncEventToCalendar(
      SyncEventToCalendarParams(eventId: eventId),
    );

    SyncedCalendarEvent? syncedEvent;

    result.fold(
      (failure) {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: failure.message,
        );
      },
      (event) {
        syncedEvent = event;
        state = state.copyWith(
          isSyncing: false,
          errorMessage: null,
        );
      },
    );

    return syncedEvent;
  }

  /// Calendar 권한 포함 Google 로그인
  Future<bool> loginWithCalendarPermission() async {
    state = state.copyWith(status: CalendarStateStatus.loading);

    final result = await _loginWithCalendar(const NoParams());

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: CalendarStateStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          status: CalendarStateStatus.success,
          hasCalendarAccess: true,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Calendar StateNotifier Provider
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(
    getCalendarStatus: ref.watch(getCalendarStatusUseCaseProvider),
    getCalendarEvents: ref.watch(getCalendarEventsUseCaseProvider),
    syncEventToCalendar: ref.watch(syncEventToCalendarUseCaseProvider),
    loginWithCalendar: ref.watch(loginWithCalendarUseCaseProvider),
  );
});

/// Calendar 연동 상태 Provider (편의용)
final hasCalendarAccessProvider = Provider<bool>((ref) {
  return ref.watch(calendarProvider).hasCalendarAccess;
});

/// Calendar 이벤트 목록 Provider (편의용)
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  return ref.watch(calendarProvider).events;
});
