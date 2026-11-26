// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'attendance_data.dart';

/// null 시각은 실제 기기 시각, 값이 있으면 고정된 테스트 시각입니다.
class ClockSelection {
  const ClockSelection(this.time);
  final DateTime? time;
}

class TestingClockSheet extends StatefulWidget {
  const TestingClockSheet({
    super.key,
    required this.now,
    required this.isTesting,
  });

  final DateTime now;
  final bool isTesting;

  @override
  State<TestingClockSheet> createState() => _TestingClockSheetState();
}

class _TestingClockSheetState extends State<TestingClockSheet> {
  late DateTime _draft = widget.now;

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _draft,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: '테스트할 날짜 선택',
    );
    if (date == null || !mounted) return;
    setState(() {
      _draft = DateTime(
        date.year,
        date.month,
        date.day,
        _draft.hour,
        _draft.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: '테스트할 시간 입력',
    );
    if (time == null || !mounted) return;
    setState(() {
      _draft = DateTime(
        _draft.year,
        _draft.month,
        _draft.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${_draft.hour.toString().padLeft(2, '0')}:${_draft.minute.toString().padLeft(2, '0')}';
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '테스트 시간',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '날짜와 시간을 바꿔 출석 과정을 확인하세요.\n기기의 실제 시간은 변경되지 않아요.',
              style: TextStyle(color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const ValueKey('pick-test-date'),
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 19),
              label: Text('${_draft.year}년 ${_draft.month}월 ${_draft.day}일'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('pick-test-time'),
              onPressed: _chooseTime,
              icon: const Icon(Icons.schedule_outlined, size: 20),
              label: Text(timeLabel),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('mockup-time-preset'),
              onPressed: () =>
                  setState(() => _draft = DateTime(2026, 10, 27, 15, 35)),
              icon: const Icon(Icons.bolt_outlined, size: 20),
              label: const Text('예시 시간으로 맞추기 · 화 15:35'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '테스트용 출석 코드: ${AttendanceController.demoCode}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '월 10:00–11:15  컴퓨터네트워크\n화 15:30–16:45  모바일앱프로그래밍\n수 09:00–10:15  운영체제\n목 13:30–14:45  자료구조',
                    style: TextStyle(fontSize: 13, height: 1.7),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '더미 학기: 3월·9월부터 16주\n적용한 시간은 고정되며 앱 재시작 시 해제돼요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('apply-test-time'),
              onPressed: () => Navigator.pop(context, ClockSelection(_draft)),
              child: const Text('이 시간으로 테스트'),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const ValueKey('restore-real-time'),
              onPressed: () =>
                  Navigator.pop(context, const ClockSelection(null)),
              child: Text(widget.isTesting ? '현재 시간으로 돌아가기' : '현재 시간 유지하기'),
            ),
          ],
        ),
      ),
    );
  }
}
