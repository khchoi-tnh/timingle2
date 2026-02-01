/// Calendar Feature - Google Calendar 연동
///
/// 사용 예시:
/// ```dart
/// import 'package:frontend/features/calendar/calendar.dart';
///
/// // Provider 사용
/// final hasAccess = ref.watch(hasCalendarAccessProvider);
///
/// // 위젯 사용
/// CalendarSyncButton(eventId: event.id)
/// ```
library calendar;

// Domain - Entities
export 'domain/entities/calendar_event.dart';

// Domain - Repositories
export 'domain/repositories/calendar_repository.dart';

// Domain - UseCases
export 'domain/usecases/get_calendar_events.dart';
export 'domain/usecases/get_calendar_status.dart';
export 'domain/usecases/login_with_calendar.dart';
export 'domain/usecases/sync_event_to_calendar.dart';

// Presentation - Providers
export 'presentation/providers/calendar_provider.dart';

// Presentation - Widgets
export 'presentation/widgets/calendar_sync_button.dart';
