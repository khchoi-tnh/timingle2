import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/features/timingle/domain/entities/event.dart';
import 'package:frontend/features/timingle/presentation/widgets/event_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  Event createTestEvent({
    int id = 1,
    String title = 'Test Event',
    String status = AppConstants.statusProposed,
    String? location,
    List<EventParticipant> participants = const [],
    int? unreadMessages,
  }) {
    return Event(
      id: id,
      title: title,
      startTime: DateTime(2024, 6, 15, 14, 0),
      endTime: DateTime(2024, 6, 15, 16, 0),
      status: status,
      location: location,
      creatorId: 1,
      participants: participants,
      unreadMessages: unreadMessages,
      createdAt: DateTime(2024, 6, 1),
    );
  }

  Widget createEventCard(Event event, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: EventCard(
          event: event,
          onTap: onTap,
        ),
      ),
    );
  }

  group('EventCard', () {
    testWidgets('displays event title', (tester) async {
      final event = createTestEvent(title: '팀 회의');
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('팀 회의'), findsOneWidget);
    });

    testWidgets('displays status badge', (tester) async {
      final event = createTestEvent(status: AppConstants.statusConfirmed);
      await tester.pumpWidget(createEventCard(event));

      // StatusBadge should show 확정 for CONFIRMED status
      expect(find.text('확정'), findsOneWidget);
    });

    testWidgets('displays proposed status badge', (tester) async {
      final event = createTestEvent(status: AppConstants.statusProposed);
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('미확정'), findsOneWidget);
    });

    testWidgets('displays location when provided', (tester) async {
      final event = createTestEvent(location: '강남역 스타벅스');
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('강남역 스타벅스'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('does not display location icon when no location', (tester) async {
      final event = createTestEvent(location: null);
      await tester.pumpWidget(createEventCard(event));

      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('displays time icon', (tester) async {
      final event = createTestEvent();
      await tester.pumpWidget(createEventCard(event));

      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('displays unread badge when has unread messages', (tester) async {
      final event = createTestEvent(unreadMessages: 5);
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does not display unread badge when no unread messages', (tester) async {
      final event = createTestEvent(unreadMessages: 0);
      await tester.pumpWidget(createEventCard(event));

      // UnreadBadge should not be visible when count is 0
      expect(find.text('0'), findsNothing);
    });

    testWidgets('displays participants avatars', (tester) async {
      final event = createTestEvent(
        participants: [
          const EventParticipant(id: 1, name: '김철수'),
          const EventParticipant(id: 2, name: '이영희'),
        ],
      );
      await tester.pumpWidget(createEventCard(event));

      // AvatarStack should be rendered
      // Check for avatar initials
      expect(find.text('김'), findsOneWidget);
      expect(find.text('이'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      final event = createTestEvent();
      await tester.pumpWidget(createEventCard(
        event,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(EventCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays canceled status badge', (tester) async {
      final event = createTestEvent(status: AppConstants.statusCanceled);
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('취소됨'), findsOneWidget);
    });

    testWidgets('displays done status badge', (tester) async {
      final event = createTestEvent(status: AppConstants.statusDone);
      await tester.pumpWidget(createEventCard(event));

      expect(find.text('완료'), findsOneWidget);
    });

    testWidgets('truncates long title', (tester) async {
      final event = createTestEvent(
        title: '아주 길고 긴 이벤트 제목이 여기에 들어갑니다 이것은 매우 긴 제목입니다',
      );
      await tester.pumpWidget(createEventCard(event));

      // Title should be truncated with ellipsis
      final titleFinder = find.text(
        '아주 길고 긴 이벤트 제목이 여기에 들어갑니다 이것은 매우 긴 제목입니다',
      );
      expect(titleFinder, findsOneWidget);

      final text = tester.widget<Text>(titleFinder);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders without participants', (tester) async {
      final event = createTestEvent(participants: []);
      await tester.pumpWidget(createEventCard(event));

      // Should render without error
      expect(find.byType(EventCard), findsOneWidget);
    });
  });
}
