import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/core/widgets/status_badge.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('PROPOSED 상태는 "미확정" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AppConstants.statusProposed),
          ),
        ),
      );

      expect(find.text('미확정'), findsOneWidget);
    });

    testWidgets('CONFIRMED 상태는 "확정" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AppConstants.statusConfirmed),
          ),
        ),
      );

      expect(find.text('확정'), findsOneWidget);
    });

    testWidgets('CANCELED 상태는 "취소됨" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AppConstants.statusCanceled),
          ),
        ),
      );

      expect(find.text('취소됨'), findsOneWidget);
    });

    testWidgets('DONE 상태는 "완료" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: AppConstants.statusDone),
          ),
        ),
      );

      expect(find.text('완료'), findsOneWidget);
    });

    testWidgets('알 수 없는 상태는 원본 문자열 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'UNKNOWN'),
          ),
        ),
      );

      expect(find.text('UNKNOWN'), findsOneWidget);
    });

    testWidgets('compact 모드는 작은 패딩 사용', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: AppConstants.statusConfirmed,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('확정'), findsOneWidget);
    });
  });

  group('UnreadBadge', () {
    testWidgets('count가 0일 때 렌더링하지 않음', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(count: 0),
          ),
        ),
      );

      expect(find.byType(UnreadBadge), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('count가 양수일 때 숫자 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(count: 5),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('count가 99 초과 시 "99+" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(count: 150),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('showIcon: false일 때 아이콘 숨김', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnreadBadge(count: 5, showIcon: false),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble), findsNothing);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('CustomBadge', () {
    testWidgets('텍스트 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomBadge(text: '커스텀'),
          ),
        ),
      );

      expect(find.text('커스텀'), findsOneWidget);
    });

    testWidgets('아이콘 포함 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomBadge(
              text: '알림',
              icon: Icons.notifications,
            ),
          ),
        ),
      );

      expect(find.text('알림'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });
}
