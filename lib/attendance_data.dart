import 'package:flutter/foundation.dart';

/// 화면과 분리한 더미 출결 데이터입니다. 실제 학교 서버에 저장하지 않습니다.
enum AttendanceStatus { present, excused, late, absent, unrecorded }

enum SubmissionResult {
  success,
  invalidFormat,
  incorrectCode,
  noClass,
  selectCourse,
  closed,
  alreadySubmitted,
  busy,
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.present => '출석',
    AttendanceStatus.excused => '공결',
    AttendanceStatus.late => '지각',
    AttendanceStatus.absent => '결석',
    AttendanceStatus.unrecorded => '미입력',
  };
}

/// 서버 연동 전의 학기 규칙: 3~8월은 1학기, 9~2월은 2학기입니다.
/// 주차별 더미 수업은 학기 시작일부터 16주까지만 생성합니다.
@immutable
class Semester {
  const Semester(this.year, this.number);

  factory Semester.fromDate(DateTime date) {
    if (date.month < 3) return Semester(date.year - 1, 2);
    return Semester(date.year, date.month < 9 ? 1 : 2);
  }

  final int year;
  final int number;

  String get label => '$year년 $number학기';
  String get key => '$year-$number';
  DateTime get start => DateTime(year, number == 1 ? 3 : 9);
  DateTime get endExclusive =>
      number == 1 ? DateTime(year, 9) : DateTime(year + 1, 3);
  DateTime get teachingEndExclusive => start.add(const Duration(days: 112));

  bool isTeachingDay(DateTime date) =>
      !date.isBefore(start) && date.isBefore(teachingEndExclusive);
}

@immutable
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.category,
    required this.room,
    required this.weekday,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final String id;
  final String name;
  final String category;
  final String room;
  final int weekday;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  String get weekdayLabel => _weekdays[weekday - 1];
  String get startLabel => _time(startHour, startMinute);
  String get endLabel => _time(endHour, endMinute);
  String get timeRange => '$startLabel–$endLabel';

  ClassSession sessionOn(DateTime date) => ClassSession(
    course: this,
    start: DateTime(date.year, date.month, date.day, startHour, startMinute),
    end: DateTime(date.year, date.month, date.day, endHour, endMinute),
  );

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

@immutable
class ClassSession {
  const ClassSession({
    required this.course,
    required this.start,
    required this.end,
  });

  final Course course;
  final DateTime start;
  final DateTime end;

  String get key => '${course.id}:${start.toIso8601String()}';

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);
}

const mockCourses = <Course>[
  Course(
    id: 'mobile',
    name: '모바일앱프로그래밍',
    category: '전공선택',
    room: 'IT융합관 302호',
    weekday: DateTime.tuesday,
    startHour: 15,
    startMinute: 30,
    endHour: 16,
    endMinute: 45,
  ),
  Course(
    id: 'network',
    name: '컴퓨터네트워크',
    category: '전공선택',
    room: 'IT융합관 305호',
    weekday: DateTime.monday,
    startHour: 10,
    startMinute: 0,
    endHour: 11,
    endMinute: 15,
  ),
  Course(
    id: 'data',
    name: '자료구조',
    category: '전공필수',
    room: 'IT융합관 304호',
    weekday: DateTime.thursday,
    startHour: 13,
    startMinute: 30,
    endHour: 14,
    endMinute: 45,
  ),
  Course(
    id: 'os',
    name: '운영체제',
    category: '전공필수',
    room: 'IT융합관 303호',
    weekday: DateTime.wednesday,
    startHour: 9,
    startMinute: 0,
    endHour: 10,
    endMinute: 15,
  ),
];

/// 작은 과제 앱에서 사용할 메모리 기반 상태입니다.
/// 새로고침/화면 이동에서는 유지되고 앱을 완전히 재시작하면 초기화됩니다.
class AttendanceController extends ChangeNotifier {
  AttendanceController({
    DateTime Function()? clock,
    this.delay = const Duration(milliseconds: 450),
    List<Course>? courses,
  }) : _clock = clock ?? DateTime.now,
       courses = List.unmodifiable(courses ?? mockCourses) {
    _now = _clock();
    _createdAt = _now;
  }

  static const demoCode = 'AB';
  final DateTime Function() _clock;
  final Duration delay;
  final List<Course> courses;
  late DateTime _now;
  late final DateTime _createdAt;
  bool _isSubmitting = false;
  bool _disposed = false;
  final Map<String, AttendanceStatus> _submitted = {};
  final Map<String, DateTime> _lastUpdated = {};
  final Map<String, Future<void>> _refreshes = {};

  DateTime get now => _now;
  Semester get semester => Semester.fromDate(now);
  bool get isSubmitting => _isSubmitting;

  List<Course> get currentCourses {
    if (!semester.isTeachingDay(now)) return const [];
    return courses
        .where(
          (course) =>
              course.weekday == now.weekday &&
              course.sessionOn(now).contains(now),
        )
        .toList(growable: false);
  }

  Course? get activeCourse {
    final current = currentCourses;
    return current.length == 1 ? current.single : null;
  }

  ClassSession? get nextSession {
    ClassSession? next;
    for (final course in courses) {
      for (final session in _sessionsFor(course)) {
        if (!session.start.isAfter(now)) continue;
        if (next == null || session.start.isBefore(next.start)) next = session;
        break;
      }
    }
    return next;
  }

  void tick() {
    if (_disposed) return;
    final updated = _clock();
    if (updated == _now) return;
    _now = updated;
    notifyListeners();
  }

  bool hasSubmitted(Course course) =>
      _submitted.containsKey(course.sessionOn(now).key);

  Map<AttendanceStatus, int> countsFor(Course course) {
    final counts = {for (final status in AttendanceStatus.values) status: 0};
    var index = 0;
    for (final session in _sessionsFor(course)) {
      final saved = _submitted[session.key];
      if (saved != null && !now.isBefore(session.start)) {
        counts[saved] = counts[saved]! + 1;
      } else if (!now.isBefore(session.end)) {
        final status = _historicalStatus(course, index, session);
        counts[status] = counts[status]! + 1;
      }
      index++;
    }
    return Map.unmodifiable(counts);
  }

  DateTime? lastUpdatedFor(Course course) {
    final updated = _lastUpdated[_courseKey(course)] ?? _createdAt;
    // 테스트 시계를 과거로 옮겨도 미래의 업데이트 시각을 표시하지 않습니다.
    return updated.isAfter(now) ? now : updated;
  }

  bool isRefreshing(Course course) =>
      _refreshes.containsKey(_courseKey(course));

  Future<void> refreshCourse(Course course) {
    if (_disposed) return Future.value();
    final key = _courseKey(course);
    final pending = _refreshes[key];
    if (pending != null) return pending;
    final future = _refreshCourse(course, key);
    _refreshes[key] = future;
    notifyListeners();
    return future;
  }

  Future<void> _refreshCourse(Course course, String key) async {
    try {
      await Future<void>.delayed(delay);
      if (_disposed) return;
      _now = _clock();
      _lastUpdated[key] = _now;
    } finally {
      _refreshes.remove(key);
      _notify();
    }
  }

  Future<SubmissionResult> submitCode(String code) async {
    if (_disposed) return SubmissionResult.closed;
    if (_isSubmitting) return SubmissionResult.busy;
    tick();
    if (currentCourses.isEmpty) return SubmissionResult.noClass;
    final course = activeCourse;
    if (course == null) return SubmissionResult.selectCourse;
    if (hasSubmitted(course)) return SubmissionResult.alreadySubmitted;
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      return SubmissionResult.invalidFormat;
    }

    final requestedSession = course.sessionOn(now);
    _isSubmitting = true;
    notifyListeners();
    try {
      await Future<void>.delayed(delay);
      if (_disposed) return SubmissionResult.closed;
      _now = _clock();
      if (!requestedSession.contains(now) ||
          !semester.isTeachingDay(now) ||
          activeCourse?.id != course.id) {
        return SubmissionResult.closed;
      }
      if (_submitted.containsKey(requestedSession.key)) {
        return SubmissionResult.alreadySubmitted;
      }
      if (normalized != demoCode) return SubmissionResult.incorrectCode;
      _submitted[requestedSession.key] = AttendanceStatus.present;
      _lastUpdated[_courseKey(course)] = now;
      return SubmissionResult.success;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  String _courseKey(Course course) => '${semester.key}:${course.id}';

  Iterable<ClassSession> _sessionsFor(Course course) sync* {
    final first = semester.start.add(
      Duration(days: (course.weekday - semester.start.weekday + 7) % 7),
    );
    for (
      var date = first;
      date.isBefore(semester.teachingEndExclusive);
      date = date.add(const Duration(days: 7))
    ) {
      yield course.sessionOn(date);
    }
  }

  AttendanceStatus _historicalStatus(
    Course course,
    int index,
    ClassSession session,
  ) {
    // 앱 실행 뒤 마감된 수업을 자동 출석으로 채우지 않습니다.
    if (session.end.isAfter(_createdAt)) return AttendanceStatus.unrecorded;
    if (course.id == 'network' && index == 2) return AttendanceStatus.late;
    if (course.id == 'data' && index == 3) return AttendanceStatus.excused;
    if (course.id == 'os' && index == 1) return AttendanceStatus.absent;
    return AttendanceStatus.present;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
