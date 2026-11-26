// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/attendance_screens.dart';
import 'package:my_flutter_app/attendance_tab.dart';

Finder _keyed(String value) => find.byKey(ValueKey(value));

void _setSurface(WidgetTester tester, [Size size = const Size(390, 844)]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetViewInsets);
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('ko', 'KR'),
  supportedLocales: const [Locale('ko', 'KR')],
  // 호스트의 SDK MaterialApp에 맞는 지역화를 제공합니다.
  // ignore: deprecated_member_use
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _usePreset(WidgetTester tester) async {
  await _tap(tester, _keyed('open-test-clock'));
  await _tap(tester, _keyed('mockup-time-preset'));
  await _tap(tester, _keyed('apply-test-time'));
  expect(find.text('모바일앱프로그래밍'), findsOneWidget);
  expect(_keyed('clear-test-time'), findsOneWidget);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.enterText(_keyed('attendance-code'), 'AB');
  await _tap(tester, _keyed('submit-attendance'));
  expect(find.text('출석이 확인되었어요'), findsOneWidget);
}

Future<void> _openDetail(WidgetTester tester) async {
  await _tap(tester, _keyed('choose-course'));
  await _tap(tester, _keyed('course-mobile'));
  expect(find.byType(AttendanceDetailScreen), findsOneWidget);
}

void _expectPresentNine() {
  expect(
    find.descendant(of: _keyed('count-present'), matching: find.text('9')),
    findsOneWidget,
  );
}

void main() {
  final mobilePlatforms = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  testWidgets('통합용 위젯은 호스트 하단 바 하나만 두고 한국어 시계·출석·상세를 제공한다', (tester) async {
    _setSurface(tester);
    await tester.pumpWidget(_app(const _MockHomeTab()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    final tabScaffold = find.descendant(
      of: find.byType(AttendanceTab),
      matching: find.byType(Scaffold),
    );
    expect(tabScaffold, findsOneWidget);
    expect(tester.widget<Scaffold>(tabScaffold).bottomNavigationBar, isNull);
    expect(find.text('도서관 화면'), findsNothing);
    expect(find.text('교통 화면'), findsNothing);
    expect(find.text('학식 화면'), findsNothing);

    await _usePreset(tester);
    await _tap(tester, _keyed('open-test-clock'));
    await _tap(tester, _keyed('pick-test-date'));
    final dateDialog = find.byType(DatePickerDialog);
    final dateLabels = MaterialLocalizations.of(tester.element(dateDialog));
    expect(dateLabels.okButtonLabel, '확인');
    await _tap(
      tester,
      find.descendant(
        of: dateDialog,
        matching: find.text(dateLabels.okButtonLabel),
      ),
    );
    await _tap(tester, _keyed('pick-test-time'));
    final timeDialog = find.byType(TimePickerDialog);
    final timeLabels = MaterialLocalizations.of(tester.element(timeDialog));
    expect(timeLabels.okButtonLabel, '확인');
    await _tap(
      tester,
      find.descendant(
        of: timeDialog,
        matching: find.text(timeLabels.okButtonLabel),
      ),
    );
    await _tap(tester, _keyed('apply-test-time'));
    await _submit(tester);
    await _openDetail(tester);
    _expectPresentNine();
    await _tap(tester, _keyed('refresh-attendance'));
    expect(find.byType(AttendanceDetailScreen), findsOneWidget);
    expect(find.text('모바일앱프로그래밍'), findsOneWidget);
    _expectPresentNine();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: mobilePlatforms);

  testWidgets('호스트 탭 왕복·재선택은 기록과 시간을 유지하고 숨겨진 출결은 뒤로가기를 막지 않는다', (
    tester,
  ) async {
    _setSurface(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('open-mock-host'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const _MockHomeTab()),
                ),
                child: const Text('통합 앱 열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await _tap(tester, _keyed('open-mock-host'));
    await _usePreset(tester);
    await _submit(tester);
    await _openDetail(tester);
    await _tap(tester, _keyed('host-tab-home'));
    expect(find.text('통합 앱 홈'), findsOneWidget);
    await _tap(tester, _keyed('host-tab-attendance'));
    expect(find.byType(AttendanceOverview), findsOneWidget);
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(find.text('오후 3:35'), findsOneWidget);
    expect(_keyed('clear-test-time'), findsOneWidget);

    await _openDetail(tester);
    _expectPresentNine();
    // 이미 선택된 출결 탭을 다시 누르는 경우에는 공개 진입 메서드를 사용합니다.
    await _tap(tester, _keyed('host-tab-attendance'));
    expect(find.byType(AttendanceOverview), findsOneWidget);
    expect(find.text('출석이 확인되었어요'), findsOneWidget);

    await _openDetail(tester);
    await _tap(tester, _keyed('host-tab-home'));
    // 상세 화면은 IndexedStack 안에 살아 있지만 상위 route의 pop을 막으면 안 됩니다.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_keyed('open-mock-host'), findsOneWidget);
    expect(find.byType(_MockHomeTab), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: mobilePlatforms);

  testWidgets('하단 바 없는 iOS 단독 출결 화면도 안전 영역과 키보드를 피한다', (tester) async {
    const size = Size(375, 812);
    const safeArea = FakeViewPadding(top: 44, bottom: 34);
    _setSurface(tester, size);
    tester.view.viewPadding = safeArea;
    tester.view.padding = safeArea;
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      _app(
        AttendanceTab(
          clock: () => DateTime(2026, 10, 27, 15, 35),
          enableTicker: false,
          mockDelay: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(
      tester.getTopLeft(_keyed('choose-course')).dy,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getBottomRight(find.byType(SingleChildScrollView)).dy,
      lessThanOrEqualTo(size.height - 34),
    );
    await _tap(tester, _keyed('attendance-code'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 44);
    await tester.pumpAndSettle();
    await tester.enterText(_keyed('attendance-code'), 'AB');
    await tester.ensureVisible(_keyed('submit-attendance'));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(_keyed('submit-attendance')).dy,
      lessThanOrEqualTo(size.height - 300),
    );
    await _tap(tester, _keyed('submit-attendance'));
    expect(find.text('출석이 확인되었어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

// 실제 팀 HomeTab 소스가 아니라, 공유 하단 바를 가진 호스트의 최소 계약입니다.
class _MockHomeTab extends StatefulWidget {
  const _MockHomeTab();

  @override
  State<_MockHomeTab> createState() => _MockHomeTabState();
}

class _MockHomeTabState extends State<_MockHomeTab> {
  final _attendanceKey = GlobalKey<AttendanceTabState>();
  int _index = 1;

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 1 && _index == 1) {
      _attendanceKey.currentState?.showOverview();
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        const Center(child: Text('통합 앱 홈')),
        AttendanceTab(
          key: _attendanceKey,
          isActive: _index == 1,
          clock: () => DateTime(2026, 10, 25, 12),
          enableTicker: false,
          mockDelay: Duration.zero,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      destinations: const [
        NavigationDestination(
          key: ValueKey('host-tab-home'),
          icon: Icon(Icons.home_outlined),
          label: '홈',
        ),
        NavigationDestination(
          key: ValueKey('host-tab-attendance'),
          icon: Icon(Icons.fact_check_outlined),
          label: '출결',
        ),
      ],
    ),
  );
}
