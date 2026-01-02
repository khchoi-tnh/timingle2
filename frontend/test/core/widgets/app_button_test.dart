import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_button.dart';

void main() {
  group('AppButton', () {
    testWidgets('primary 버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: '확인',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('확인'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('secondary 버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.secondary(
              text: '보조',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('보조'), findsOneWidget);
    });

    testWidgets('outline 버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.outline(
              text: '테두리',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('테두리'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text 버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.text(
              text: '텍스트',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('텍스트'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('isLoading: true일 때 로딩 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: '로딩',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('로딩'), findsNothing);
    });

    testWidgets('onPressed가 호출됨', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: '클릭',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('isLoading: true일 때 버튼 비활성화', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: '로딩',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('아이콘 포함 버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: '추가',
              onPressed: () {},
              icon: Icons.add,
            ),
          ),
        ),
      );

      expect(find.text('추가'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('다양한 크기 렌더링', (tester) async {
      for (final size in AppButtonSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton.primary(
                text: '버튼',
                onPressed: () {},
                size: size,
              ),
            ),
          ),
        );

        expect(find.text('버튼'), findsOneWidget);
      }
    });
  });
}
