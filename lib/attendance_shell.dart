// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'attendance_tab.dart';

/// 이 프로젝트를 단독 실행할 때 사용하는 다섯 탭의 시연용 껍데기입니다.
/// 팀 앱에는 이 위젯 대신 AttendanceTab을 넣습니다.
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

class _AttendanceShellState extends State<AttendanceShell> {
  final _attendanceKey = GlobalKey<AttendanceTabState>();
  int _tab = 1;
  static const _titles = ['홈', '전자출결', '도서관', '교통', '학식'];

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 1) _attendanceKey.currentState?.showOverview();
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tab == 1
          ? null
          : AppBar(toolbarHeight: 72, title: Text(_titles[_tab])),
      // 같은 출결 위젯을 유지해야 다른 탭에 다녀와도 출석 기록이 남습니다.
      body: IndexedStack(
        index: _tab,
        children: [
          const _TeamPagePlaceholder(title: '홈'),
          AttendanceTab(
            key: _attendanceKey,
            isActive: _tab == 1,
            clock: widget.clock,
            enableTicker: widget.enableTicker,
            mockDelay: widget.mockDelay,
          ),
          const _TeamPagePlaceholder(title: '도서관'),
          const _TeamPagePlaceholder(title: '교통'),
          const _TeamPagePlaceholder(title: '학식'),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
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
    );
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
