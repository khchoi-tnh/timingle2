import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/avatar_stack.dart';

void main() {
  group('AvatarStack', () {
    testWidgets('빈 리스트일 때 "참여자 없음" 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(avatars: []),
          ),
        ),
      );

      expect(find.text('참여자 없음'), findsOneWidget);
    });

    testWidgets('아바타 1개 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(
              avatars: [AvatarData(name: '홍길동')],
            ),
          ),
        ),
      );

      expect(find.text('홍'), findsOneWidget);
      expect(find.text('1명'), findsOneWidget);
    });

    testWidgets('아바타 3개 모두 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(
              avatars: [
                AvatarData(name: '홍길동'),
                AvatarData(name: '김철수'),
                AvatarData(name: '이영희'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('홍'), findsOneWidget);
      expect(find.text('김'), findsOneWidget);
      expect(find.text('이'), findsOneWidget);
      expect(find.text('3명'), findsOneWidget);
    });

    testWidgets('아바타 5개일 때 3개만 표시하고 +2 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(
              avatars: [
                AvatarData(name: '홍길동'),
                AvatarData(name: '김철수'),
                AvatarData(name: '이영희'),
                AvatarData(name: '박지민'),
                AvatarData(name: '최수진'),
              ],
              maxDisplay: 3,
            ),
          ),
        ),
      );

      expect(find.text('+2'), findsOneWidget);
      expect(find.text('5명'), findsOneWidget);
    });

    testWidgets('showCount: false일 때 인원수 숨김', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(
              avatars: [AvatarData(name: '홍길동')],
              showCount: false,
            ),
          ),
        ),
      );

      expect(find.text('홍'), findsOneWidget);
      expect(find.text('1명'), findsNothing);
    });

    testWidgets('빈 이름일 때 ? 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarStack(
              avatars: [AvatarData(name: '')],
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('UserAvatar', () {
    testWidgets('이름 첫 글자 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: '홍길동'),
          ),
        ),
      );

      expect(find.text('홍'), findsOneWidget);
    });

    testWidgets('빈 이름일 때 ? 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: ''),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('onTap 콜백 호출', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: '홍길동',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserAvatar));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('showBorder: true일 때 테두리 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: '홍길동',
              showBorder: true,
            ),
          ),
        ),
      );

      expect(find.text('홍'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
