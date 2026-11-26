// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/attendance_data.dart';
import 'package:my_flutter_app/attendance_screens.dart';

void main() {
  testWidgets(
    '팀 MaterialApp에 세 화면을 직접 넣어 테마·한국어·출석을 공유한다',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 15, 35),
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      const hostPrimary = Color(0xFF1565C0);

      // 출결 앱의 MyFlutterApp이나 AttendanceShell 없이 팀 앱의 상위 구조를 재현합니다.
      Future<void> pumpInTeamApp(Widget screen) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: hostPrimary),
            ),
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [Locale('ko', 'KR')],
            // SDK MaterialApp에 맞는 지역화 delegate입니다.
            // ignore: deprecated_member_use
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await pumpInTeamApp(
        AttendanceOverview(controller: controller, onChooseCourse: () {}),
      );
      final input = find.byType(TextField);
      expect(input, findsOneWidget);
      final inputContext = tester.element(input);
      expect(
        Theme.of(inputContext).colorScheme,
        ColorScheme.fromSeed(seedColor: hostPrimary),
      );
      expect(MaterialLocalizations.of(inputContext).okButtonLabel, '확인');
      await tester.enterText(input, 'AB');
      final submit = find.byKey(const ValueKey('submit-attendance'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('출석이 확인되었어요'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.takeException(), isNull);

      Course? selected;
      await pumpInTeamApp(
        CourseSelectionScreen(
          controller: controller,
          onSelectCourse: (course) => selected = course,
        ),
      );
      final mobile = find.byKey(const ValueKey('course-mobile'));
      expect(tester.widget<InkWell>(mobile).onTap, isNotNull);
      await tester.tap(mobile);
      await tester.pumpAndSettle();
      expect(selected?.id, 'mobile');

      await pumpInTeamApp(
        AttendanceDetailScreen(controller: controller, course: selected!),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('모바일앱프로그래밍'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('count-present')),
          matching: find.text('9'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
