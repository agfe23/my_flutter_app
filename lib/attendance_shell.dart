import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'attendance_data.dart';
import 'attendance_screens.dart';
import 'testing_clock_sheet.dart';

enum _AttendancePage { overview, courses, detail }

/// 출결 탭은 항상 기본 출결 화면으로 진입합니다.
class AttendanceShell extends StatefulWidget {
  const AttendanceShell({
    super.key,
    this.clock,
    this.enableTicker = true,
    this.mockDelay = const Duration(milliseconds: 450),
  });

  final DateTime Function()? clock;
  final bool enableTicker;
  final Duration mockDelay;

  @override
  State<AttendanceShell> createState() => _AttendanceShellState();
}

class _AttendanceShellState extends State<AttendanceShell>
    with WidgetsBindingObserver {
  late final AttendanceController _controller;
  Timer? _ticker;
  DateTime? _testTime;
  int _tab = 1;
  _AttendancePage _page = _AttendancePage.overview;
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _controller = AttendanceController(
      clock: () => _testTime ?? widget.clock?.call() ?? DateTime.now(),
      delay: widget.mockDelay,
    );
    if (widget.enableTicker) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _controller.tick(),
      );
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.tick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openAttendance() {
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.tick();
    setState(() {
      _tab = 1;
      _page = _AttendancePage.overview;
    });
  }

  void _chooseCourse() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _page = _AttendancePage.courses);
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _page = _page == _AttendancePage.detail
          ? _AttendancePage.courses
          : _AttendancePage.overview;
    });
  }

  Future<void> _editClock() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selection = await showModalBottomSheet<ClockSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (_) =>
          TestingClockSheet(now: _controller.now, isTesting: _testTime != null),
    );
    if (!mounted || selection == null) return;
    setState(() => _testTime = selection.time);
    _controller.tick();
  }

  void _restoreClock() {
    setState(() => _testTime = null);
    _controller.tick();
  }

  String get _title => _tab != 1
      ? ['홈', '', '도서관', '교통', '학식'][_tab]
      : switch (_page) {
          _AttendancePage.overview => '전자출결',
          _AttendancePage.courses => '과목 선택',
          _AttendancePage.detail => '출석 상세',
        };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final hasBack = _tab == 1 && _page != _AttendancePage.overview;
        return PopScope(
          canPop: !hasBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && hasBack) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 72,
              leading: hasBack
                  ? IconButton(
                      tooltip: '이전 화면',
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              titleSpacing: hasBack ? 0 : 24,
              title: Text(_title),
              actions: [
                if (_tab == 1 && _page == _AttendancePage.overview)
                  TextButton(
                    key: const ValueKey('choose-course'),
                    onPressed: _chooseCourse,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blush,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        '과목 선택',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                if (_tab == 1 && _page == _AttendancePage.detail)
                  IconButton(
                    key: const ValueKey('refresh-attendance'),
                    tooltip: '출결 새로고침',
                    onPressed: _controller.isRefreshing(_selectedCourse!)
                        ? null
                        : () => _controller.refreshCourse(_selectedCourse!),
                    icon: _controller.isRefreshing(_selectedCourse!)
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                if (_tab == 1)
                  IconButton(
                    key: const ValueKey('open-test-clock'),
                    tooltip: '테스트 시간 설정',
                    onPressed: _controller.isSubmitting ? null : _editClock,
                    icon: const Icon(Icons.schedule_outlined, size: 22),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  if (_tab == 1 && _testTime != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: AppColors.blush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '테스트 시간 · ${_testTime!.month}/${_testTime!.day}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('clear-test-time'),
                            onPressed: _controller.isSubmitting
                                ? null
                                : _restoreClock,
                            child: const Text('해제'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: _body()),
                ],
              ),
            ),
            bottomNavigationBar: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) {
                  if (index == 1) {
                    _openAttendance();
                  } else {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _tab = index);
                  }
                },
                destinations: const [
                  NavigationDestination(
                    key: ValueKey('tab-home'),
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: '홈',
                  ),
                  NavigationDestination(
                    key: ValueKey('tab-attendance'),
                    icon: Icon(Icons.fact_check_outlined),
                    selectedIcon: Icon(Icons.fact_check_rounded),
                    label: '출결',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.local_library_outlined),
                    label: '도서관',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.directions_bus_outlined),
                    label: '교통',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.restaurant_outlined),
                    label: '학식',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_tab != 1) return _TeamPagePlaceholder(title: _title);
    return switch (_page) {
      _AttendancePage.overview => AttendanceOverview(
        controller: _controller,
        onChooseCourse: _chooseCourse,
      ),
      _AttendancePage.courses => CourseSelectionScreen(
        controller: _controller,
        onSelectCourse: (course) {
          setState(() {
            _selectedCourse = course;
            _page = _AttendancePage.detail;
          });
        },
      ),
      _AttendancePage.detail => AttendanceDetailScreen(
        key: ValueKey(_selectedCourse!.id),
        controller: _controller,
        course: _selectedCourse!,
      ),
    };
  }
}

class _TeamPagePlaceholder extends StatelessWidget {
  const _TeamPagePlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apps_rounded, size: 40, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            '$title 화면',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}
