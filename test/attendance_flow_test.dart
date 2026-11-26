import 'package:flutter_test/flutter_test.dart';
// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:my_flutter_app/attendance_screens.dart';
import 'package:my_flutter_app/main.dart';

Finder keyed(String value) => find.byKey(ValueKey(value));

Future<void> pumpAttendance(
  WidgetTester tester, {
  DateTime? time,
  DateTime Function()? clock,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MyFlutterApp(
      clock: clock ?? () => time ?? DateTime(2026, 10, 27, 15, 35),
      enableTicker: false,
      mockDelay: Duration.zero,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openDetail(WidgetTester tester, String courseId) async {
  await tapVisible(tester, keyed('choose-course'));
  expect(find.byType(CourseSelectionScreen), findsOneWidget);
  await tapVisible(tester, keyed('course-$courseId'));
  expect(find.byType(AttendanceDetailScreen), findsOneWidget);
}

void expectCount(String status, int count) {
  expect(
    find.descendant(of: keyed('count-$status'), matching: find.text('$count')),
    findsOneWidget,
  );
}

void main() {
  // Windows에서도 두 모바일 플랫폼의 위젯 동작을 각각 검증합니다.
  final mobilePlatforms = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });
  testWidgets('01→02→03에서 과목을 유지하여 새로고침하고 순서대로 돌아간다', (tester) async {
    await pumpAttendance(tester);
    expect(find.byType(AttendanceOverview), findsOneWidget);
    await openDetail(tester, 'data');
    expect(find.text('자료구조'), findsOneWidget);
    expectCount('present', 7);
    expectCount('excused', 1);

    await tapVisible(tester, keyed('refresh-attendance'));
    expect(find.byType(AttendanceDetailScreen), findsOneWidget);
    expect(find.text('자료구조'), findsOneWidget);
    expectCount('present', 7);
    expectCount('excused', 1);
    expect(find.text('최종 업데이트 15:35'), findsOneWidget);

    // Android의 시스템 뒤로 가기도 상세→목록 한 단계만 이동해야 합니다.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CourseSelectionScreen), findsOneWidget);
    await tapVisible(tester, find.byTooltip('이전 화면'));
    expect(find.byType(AttendanceOverview), findsOneWidget);
  }, variant: mobilePlatforms);

  testWidgets('상세 화면과 다른 탭에서 출결을 누르면 항상 01 화면으로 진입한다', (tester) async {
    await pumpAttendance(tester);
    await openDetail(tester, 'network');
    await tapVisible(tester, keyed('tab-attendance'));
    expect(find.byType(AttendanceOverview), findsOneWidget);
    expect(find.byType(AttendanceDetailScreen), findsNothing);

    for (final label in ['홈', '도서관', '교통', '학식']) {
      await openDetail(tester, 'os');
      await tapVisible(
        tester,
        find.byWidgetPredicate(
          (widget) => widget is NavigationDestination && widget.label == label,
        ),
      );
      expect(find.text('$label 화면'), findsOneWidget);
      await tapVisible(tester, keyed('tab-attendance'));
      expect(find.byType(AttendanceOverview), findsOneWidget);
      expect(keyed('attendance-code'), findsOneWidget);
    }
  }, variant: mobilePlatforms);

  testWidgets('현재 학기 과목을 실제 수업의 요일 순서로 표시한다', (tester) async {
    await pumpAttendance(tester);
    await tapVisible(tester, keyed('choose-course'));

    // 월→화→수→목 순서이며, 각 행을 눌렀을 때의 과목 연결도 확인합니다.
    const courseIds = ['network', 'mobile', 'os', 'data'];
    for (var index = 0; index < courseIds.length - 1; index++) {
      expect(
        tester.getTopLeft(keyed('course-${courseIds[index]}')).dy,
        lessThan(tester.getTopLeft(keyed('course-${courseIds[index + 1]}')).dy),
      );
    }
    await tapVisible(tester, keyed('course-network'));
    expect(find.byType(AttendanceDetailScreen), findsOneWidget);
    expect(find.text('컴퓨터네트워크'), findsOneWidget);
  }, variant: mobilePlatforms);

  testWidgets('수업 없는 실제시간에서 조회하고 테스트 시간을 적용·해제한다', (tester) async {
    await pumpAttendance(tester, time: DateTime(2026, 10, 25, 12));
    expect(find.text('지금은 진행 중인 수업이 없어요'), findsOneWidget);
    expect(keyed('attendance-code'), findsNothing);
    expect(keyed('clear-test-time'), findsNothing);
    await tapVisible(tester, find.text('이번 학기 출결 조회'));
    expect(find.byType(CourseSelectionScreen), findsOneWidget);
    await tapVisible(tester, find.byTooltip('이전 화면'));

    await tapVisible(tester, keyed('open-test-clock'));
    expect(keyed('pick-test-date'), findsOneWidget);
    expect(keyed('pick-test-time'), findsOneWidget);
    await tapVisible(tester, keyed('mockup-time-preset'));
    await tapVisible(tester, keyed('apply-test-time'));
    expect(find.text('모바일앱프로그래밍'), findsOneWidget);
    expect(find.text('오후 3:35'), findsOneWidget);
    expect(keyed('attendance-code'), findsOneWidget);
    expect(keyed('clear-test-time'), findsOneWidget);

    await tapVisible(tester, keyed('clear-test-time'));
    expect(find.text('지금은 진행 중인 수업이 없어요'), findsOneWidget);
    expect(keyed('attendance-code'), findsNothing);
    expect(keyed('clear-test-time'), findsNothing);
  }, variant: mobilePlatforms);

  testWidgets('오입력은 집계하지 않고 성공한 출석은 재진입·새로고침에도 한 번 유지한다', (tester) async {
    await pumpAttendance(tester);
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석 코드 영문 2글자를 입력해 주세요.'), findsOneWidget);

    await tester.enterText(keyed('attendance-code'), 'a');
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석 코드 영문 2글자를 입력해 주세요.'), findsOneWidget);

    await tester.enterText(keyed('attendance-code'), 'ZZ');
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('코드가 일치하지 않아요. 다시 확인해 주세요.'), findsOneWidget);
    await openDetail(tester, 'mobile');
    expectCount('present', 8);
    await tapVisible(tester, keyed('tab-attendance'));

    // 소문자도 같은 출석 코드로 인정해야 합니다.
    await tester.enterText(keyed('attendance-code'), 'ab');
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(keyed('submit-attendance')).onPressed,
      isNull,
    );
    expect(tester.widget<TextField>(keyed('attendance-code')).readOnly, isTrue);
    await openDetail(tester, 'mobile');
    expectCount('present', 9);
    await tapVisible(tester, keyed('refresh-attendance'));
    expectCount('present', 9);
    await tapVisible(tester, keyed('tab-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(keyed('submit-attendance')).onPressed,
      isNull,
    );
  }, variant: mobilePlatforms);

  testWidgets('날짜·시간 선택기에 직접 입력하면 해당 요일 수업으로 바뀐다', (tester) async {
    await pumpAttendance(tester, time: DateTime(2026, 10, 25, 8, 5));
    expect(find.text('지금은 진행 중인 수업이 없어요'), findsOneWidget);
    await tapVisible(tester, keyed('open-test-clock'));
    await tapVisible(tester, keyed('pick-test-date'));
    final dateDialog = find.byType(DatePickerDialog);
    final dateLabels = MaterialLocalizations.of(tester.element(dateDialog));
    await tapVisible(
      tester,
      find.byTooltip(dateLabels.inputDateModeButtonLabel),
    );
    await tester.enterText(
      find.descendant(of: dateDialog, matching: find.byType(TextField)),
      dateLabels.formatCompactDate(DateTime(2026, 10, 28)),
    );
    await tapVisible(
      tester,
      find.descendant(
        of: dateDialog,
        matching: find.text(dateLabels.okButtonLabel),
      ),
    );
    expect(dateDialog, findsNothing);
    expect(find.text('2026년 10월 28일'), findsOneWidget);

    await tapVisible(tester, keyed('pick-test-time'));
    final timeDialog = find.byType(TimePickerDialog);
    final timeLabels = MaterialLocalizations.of(tester.element(timeDialog));
    Finder timeInput(String label) => find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(timeInput(timeLabels.timePickerHourLabel), '9');
    await tester.enterText(timeInput(timeLabels.timePickerMinuteLabel), '10');
    await tapVisible(
      tester,
      find.descendant(
        of: timeDialog,
        matching: find.text(timeLabels.okButtonLabel),
      ),
    );
    expect(timeDialog, findsNothing);
    expect(find.text('09:10'), findsOneWidget);
    await tapVisible(tester, keyed('apply-test-time'));
    expect(find.text('운영체제'), findsOneWidget);
    expect(find.text('오전 9:10'), findsOneWidget);
    expect(keyed('attendance-code'), findsOneWidget);

    await tapVisible(tester, keyed('open-test-clock'));
    await tapVisible(tester, keyed('restore-real-time'));
    expect(find.text('지금은 진행 중인 수업이 없어요'), findsOneWidget);
    expect(find.text('오전 8:05'), findsOneWidget);
    expect(keyed('clear-test-time'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: mobilePlatforms);

  testWidgets('320폭에서 키보드가 열려도 확인 버튼까지 스크롤하여 출석한다', (tester) async {
    await pumpAttendance(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await tapVisible(tester, keyed('attendance-code'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.enterText(keyed('attendance-code'), 'AB');
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
  }, variant: mobilePlatforms);

  // iOS 플랫폼 설정으로 공통 Flutter UI를 검사합니다.
  // 실제 iPhone 또는 macOS의 iOS 시뮬레이터 실행을 대신하지는 않습니다.
  testWidgets('iOS 플랫폼에서 출석·상세·두 새로고침 방식과 출결 재진입을 유지한다', (tester) async {
    var now = DateTime(2026, 10, 27, 15, 35);
    await pumpAttendance(tester, clock: () => now);
    expect(
      Theme.of(tester.element(find.byType(AttendanceOverview))).platform,
      TargetPlatform.iOS,
    );

    await tester.enterText(keyed('attendance-code'), 'AB');
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    await openDetail(tester, 'mobile');
    expectCount('present', 9);

    now = DateTime(2026, 10, 27, 15, 36);
    await tapVisible(tester, keyed('refresh-attendance'));
    expect(find.text('최종 업데이트 15:36'), findsOneWidget);
    expect(find.text('모바일앱프로그래밍'), findsOneWidget);
    expectCount('present', 9);

    now = DateTime(2026, 10, 27, 15, 37);
    await tester.drag(
      find.descendant(
        of: find.byType(AttendanceDetailScreen),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();
    expect(find.text('최종 업데이트 15:37'), findsOneWidget);
    expect(find.byType(AttendanceDetailScreen), findsOneWidget);
    expectCount('present', 9);

    await tapVisible(tester, find.byTooltip('이전 화면'));
    expect(find.byType(CourseSelectionScreen), findsOneWidget);
    await tapVisible(tester, keyed('tab-home'));
    expect(find.text('홈 화면'), findsOneWidget);
    await tapVisible(tester, keyed('tab-attendance'));
    expect(find.byType(AttendanceOverview), findsOneWidget);
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(keyed('submit-attendance')).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('375폭 iOS 안전영역과 키보드에서도 출석 버튼에 접근한다', (tester) async {
    const size = Size(375, 812);
    const safeArea = FakeViewPadding(top: 44, bottom: 34);
    tester.view.viewPadding = safeArea;
    tester.view.padding = safeArea;
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    await pumpAttendance(tester, size: size);

    // 상단 노치와 하단 홈 표시줄 영역을 실제 터치 요소가 피해야 합니다.
    expect(
      tester.getTopLeft(keyed('choose-course')).dy,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getBottomRight(keyed('tab-attendance')).dy,
      lessThanOrEqualTo(size.height - 34),
    );
    expect(tester.takeException(), isNull);

    await tapVisible(tester, keyed('attendance-code'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    // 키보드가 하단 안전영역을 덮어도 viewPadding은 유지됩니다.
    tester.view.padding = const FakeViewPadding(top: 44);
    await tester.pumpAndSettle();
    await tester.enterText(keyed('attendance-code'), 'ab');
    await tester.ensureVisible(keyed('submit-attendance'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(keyed('submit-attendance')).dy,
      lessThanOrEqualTo(size.height - 300),
    );
    await tapVisible(tester, keyed('submit-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    tester.view.padding = safeArea;
    await tester.pumpAndSettle();
    await openDetail(tester, 'mobile');
    expectCount('present', 9);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  for (final textScale in [1.0, 2.0]) {
    testWidgets('320폭·글자 $textScale배에서 세 화면과 시간설정에 레이아웃 오류가 없다', (
      tester,
    ) async {
      await pumpAttendance(
        tester,
        size: const Size(320, 740),
        textScale: textScale,
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, keyed('submit-attendance'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, keyed('choose-course'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, keyed('course-mobile'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, keyed('refresh-attendance'));
      expect(tester.takeException(), isNull);

      await tapVisible(tester, keyed('open-test-clock'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, keyed('mockup-time-preset'));
      await tapVisible(tester, keyed('apply-test-time'));
      expect(keyed('clear-test-time'), findsOneWidget);
      expect(find.byType(AttendanceDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: mobilePlatforms);
  }
}
