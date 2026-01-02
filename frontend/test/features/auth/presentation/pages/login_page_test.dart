import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    Widget createLoginPage() {
      return const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    testWidgets('renders app name and tagline', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
    });

    testWidgets('renders phone and name input fields', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text('전화번호'), findsOneWidget);
      expect(find.text('이름'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('shows validation error for empty phone', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Enter name but not phone
      await tester.enterText(find.byType(TextFormField).last, '홍길동');

      // Tap login button
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('전화번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for short phone', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Enter short phone
      await tester.enterText(find.byType(TextFormField).first, '010');
      await tester.enterText(find.byType(TextFormField).last, '홍길동');

      // Tap login button
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('올바른 전화번호를 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for empty name', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Enter phone but not name
      await tester.enterText(find.byType(TextFormField).first, '01012345678');

      // Tap login button
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('이름을 입력해주세요'), findsOneWidget);
    });

    testWidgets('shows validation error for short name', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Enter phone and short name
      await tester.enterText(find.byType(TextFormField).first, '01012345678');
      await tester.enterText(find.byType(TextFormField).last, '홍');

      // Tap login button
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('이름은 2글자 이상이어야 합니다'), findsOneWidget);
    });

    testWidgets('renders logo icon', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('phone field has phone hint text', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Verify hint text for phone field
      expect(find.text('01012345678'), findsOneWidget);
    });

    testWidgets('has correct background color', (tester) async {
      await tester.pumpWidget(createLoginPage());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.backgroundLight);
    });

    testWidgets('info text is displayed', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(
        find.text('전화번호로 간편하게 시작하세요\n약속이 있어야 대화가 시작됩니다'),
        findsOneWidget,
      );
    });
  });
}
