import 'package:flutter/services.dart';
// 팀 통합 앱과 같은 Material 타입을 사용합니다 (Flutter 3.50.1 기준).
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'attendance_data.dart';

/// 01. 현재 수업에서 코드를 입력하는 기본 출결 화면입니다.
class AttendanceOverview extends StatefulWidget {
  const AttendanceOverview({
    super.key,
    required this.controller,
    required this.onChooseCourse,
  });

  final AttendanceController controller;
  final VoidCallback onChooseCourse;

  @override
  State<AttendanceOverview> createState() => _AttendanceOverviewState();
}

class _AttendanceOverviewState extends State<AttendanceOverview> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  String? _sessionKey;
  SubmissionResult? _result;

  String? get _currentSessionKey =>
      widget.controller.activeCourse?.sessionOn(widget.controller.now).key;

  @override
  void initState() {
    super.initState();
    _sessionKey = _currentSessionKey;
  }

  @override
  void didUpdateWidget(covariant AttendanceOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다음 날짜/다른 수업에 이전 출석 코드와 오류를 남기지 않습니다.
    if (_sessionKey != _currentSessionKey) {
      _sessionKey = _currentSessionKey;
      _code.clear();
      _result = null;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.controller.isSubmitting) return;
    final requestedSession = _currentSessionKey;
    setState(() => _result = null);
    final result = await widget.controller.submitCode(_code.text);
    if (!mounted || requestedSession != _currentSessionKey) return;
    setState(() => _result = result);
    if (result == SubmissionResult.success ||
        result == SubmissionResult.alreadySubmitted) {
      _codeFocus.unfocus();
    }
  }

  String? get _error => switch (_result) {
    SubmissionResult.invalidFormat => '출석 코드 영문 2글자를 입력해 주세요.',
    SubmissionResult.incorrectCode => '코드가 일치하지 않아요. 다시 확인해 주세요.',
    SubmissionResult.noClass ||
    SubmissionResult.closed => '출석 가능한 시간이 지났어요. 출결 현황을 확인해 주세요.',
    SubmissionResult.selectCourse => '현재 수업 정보를 다시 확인해 주세요.',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final course = controller.activeCourse;
    final now = controller.now;
    final submitted = course != null && controller.hasSubmitted(course);

    return _PageBody(
      storageKey: 'attendance-overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_weekday(now)}요일 · ${now.month}월 ${now.day}일',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 20,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _clockLabel(now),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
                Text(
                  course == null ? '수업 시간 안내' : '현재 수업',
                  key: const ValueKey('clock-status-label'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('현재 수업'),
          const SizedBox(height: 10),
          if (course == null)
            _NoClassCard(
              controller: controller,
              onChooseCourse: widget.onChooseCourse,
            )
          else ...[
            _CurrentCourseCard(course: course),
            const SizedBox(height: 16),
            _codeCard(
              context,
              submitted: submitted,
              submitting: controller.isSubmitting,
            ),
          ],
        ],
      ),
    );
  }

  Widget _codeCard(
    BuildContext context, {
    required bool submitted,
    required bool submitting,
  }) {
    final error = _error;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(
                  label: submitted ? '출석 완료' : '지금 출석 가능',
                  icon: submitted ? Icons.check_circle_outline_rounded : null,
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: submitted,
                  child: Text(
                    submitted ? '출석이 확인되었어요' : '출석 코드 입력',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  submitted ? '이번 수업의 출석이 기록되었어요.' : '교수님이 안내한 코드를 입력하세요.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 18),
                const Text(
                  '출석확인 코드 입력',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('attendance-code'),
                  controller: _code,
                  focusNode: _codeFocus,
                  readOnly: submitted || submitting,
                  // 키보드가 올라와도 입력칸 아래 확인 버튼을 함께 드러냅니다.
                  scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: '영문 2글자',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                    semanticCounterText: '출석 코드 영문 2글자',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    errorText: error,
                    errorMaxLines: 3,
                    filled: submitted,
                    fillColor: AppColors.background,
                    suffixIcon: submitted
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCACDD5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_result != null) setState(() => _result = null);
                  },
                  onSubmitted: submitted || submitting
                      ? null
                      : (_) => _submit(),
                  onTapOutside: (_) => _codeFocus.unfocus(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('submit-attendance'),
                    onPressed: submitted || submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.blush,
                      disabledForegroundColor: AppColors.primary,
                      minimumSize: const Size(48, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (submitting) ...[
                          const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            submitted
                                ? '출석 확인 완료'
                                : submitting
                                ? '출석 확인 중…'
                                : '출석 확인하기',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 02. 현재 학기 과목만 보여 줍니다. 학기를 고르는 단계는 없습니다.
class CourseSelectionScreen extends StatelessWidget {
  const CourseSelectionScreen({
    super.key,
    required this.controller,
    required this.onSelectCourse,
  });

  final AttendanceController controller;
  final ValueChanged<Course> onSelectCourse;

  @override
  Widget build(BuildContext context) {
    // 원본 시간표는 유지하고 목록만 요일 → 시작 시각 순으로 보여 줍니다.
    final sortedCourses = [...controller.courses]
      ..sort((a, b) {
        final weekday = a.weekday.compareTo(b.weekday);
        if (weekday != 0) return weekday;
        final startTime = (a.startHour * 60 + a.startMinute).compareTo(
          b.startHour * 60 + b.startMinute,
        );
        return startTime != 0 ? startTime : a.name.compareTo(b.name);
      });
    return _PageBody(
      storageKey: 'course-selection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const _SectionTitle('현재 학기 과목'),
          const SizedBox(height: 8),
          Text(
            controller.semester.label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          if (sortedCourses.isEmpty)
            const _OutlinedCard(
              child: Text(
                '현재 학기에 등록된 과목이 없어요.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ),
          for (final course in sortedCourses)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('course-${course.id}'),
                  onTap: () => onSelectCourse(course),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 82),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.name,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 26,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 03. 같은 과목/화면을 유지하면서 출결 데이터만 새로고침합니다.
class AttendanceDetailScreen extends StatelessWidget {
  const AttendanceDetailScreen({
    super.key,
    required this.controller,
    required this.course,
  });

  final AttendanceController controller;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final counts = controller.countsFor(course);
    final updated = controller.lastUpdatedFor(course);
    return RefreshIndicator(
      onRefresh: () => controller.refreshCourse(course),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: _PageBody(
        storageKey: 'attendance-detail-${course.id}',
        // 내용이 화면보다 짧아도 당겨서 새로고침할 수 있습니다.
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전자출결  /  수업 상세',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Text(
              course.name,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.semester.label} · ${course.weekdayLabel}요일',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            _OutlinedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수업 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${course.timeRange} · ${course.room}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('출결 현황'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final status in const [
                  AttendanceStatus.present,
                  AttendanceStatus.excused,
                  AttendanceStatus.late,
                ]) ...[
                  if (status != AttendanceStatus.present)
                    const SizedBox(width: 8),
                  Expanded(
                    child: _CountCard(status: status, count: counts[status]!),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CountCard(
                    status: AttendanceStatus.absent,
                    count: counts[AttendanceStatus.absent]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountCard(
                    status: AttendanceStatus.unrecorded,
                    count: counts[AttendanceStatus.unrecorded]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EFED),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Text(
                  controller.isRefreshing(course)
                      ? '출결 정보를 새로고침하고 있어요…'
                      : '최종 업데이트 ${updated == null ? '—' : _timeLabel(updated)}',
                  key: const ValueKey('last-updated'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentCourseCard extends StatelessWidget {
  const _CurrentCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${course.weekdayLabel} ${course.startLabel} · ${course.category}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoClassCard extends StatelessWidget {
  const _NoClassCard({required this.controller, required this.onChooseCourse});

  final AttendanceController controller;
  final VoidCallback onChooseCourse;

  @override
  Widget build(BuildContext context) {
    final next = controller.nextSession;
    return _OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 16),
          const Text(
            '지금은 진행 중인 수업이 없어요',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '수업이 시작되면 출석할 과목을 자동으로 보여드려요.',
            style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.6),
          ),
          if (next != null) ...[
            const SizedBox(height: 22),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 18),
            const Text(
              '다음 수업',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 7),
            Text(
              next.course.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${next.start.month}월 ${next.start.day}일 '
              '(${next.course.weekdayLabel}) ${next.course.timeRange}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChooseCourse,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('이번 학기 출결 조회'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.status, required this.count});

  final AttendanceStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('count-${status.name}'),
      label: '${status.label} $count회',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 89),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.storageKey,
    required this.child,
    this.physics,
  });

  final String storageKey;
  final Widget child;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    // 키보드와 큰 글씨를 사용할 때도 마지막 버튼까지 스크롤됩니다.
    return SingleChildScrollView(
      key: PageStorageKey(storageKey),
      physics: physics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
  );
}

String _weekday(DateTime time) =>
    const ['월', '화', '수', '목', '금', '토', '일'][time.weekday - 1];

String _clockLabel(DateTime time) {
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$period $hour:${time.minute.toString().padLeft(2, '0')}';
}

String _timeLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
