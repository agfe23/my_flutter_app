import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/attendance_data.dart';

void main() {
  group('자동 학기 선택', () {
    test('1월과 2월은 전년도 2학기를 유지한다', () {
      expect(Semester.fromDate(DateTime(2027, 1, 1)).label, '2026년 2학기');
      expect(Semester.fromDate(DateTime(2027, 2, 28)).label, '2026년 2학기');
      expect(Semester.fromDate(DateTime(2027, 3, 1)).label, '2027년 1학기');
      expect(Semester.fromDate(DateTime(2027, 8, 31)).number, 1);
      expect(Semester.fromDate(DateTime(2027, 9, 1)).number, 2);
    });

    test('방학에는 현재 수업이나 다음 수업을 만들지 않는다', () {
      final controller = AttendanceController(
        clock: () => DateTime(2027, 1, 5, 15, 35),
      );
      addTearDown(controller.dispose);
      expect(controller.currentCourses, isEmpty);
      expect(controller.nextSession, isNull);
    });
  });

  group('현재 수업 판단', () {
    test('수업 시작 시각은 포함하고 종료 시각은 제외한다', () {
      var time = DateTime(2026, 10, 27, 15, 29, 59);
      final controller = AttendanceController(clock: () => time);
      addTearDown(controller.dispose);
      expect(controller.activeCourse, isNull);
      expect(controller.nextSession?.course.id, 'mobile');
      time = DateTime(2026, 10, 27, 15, 30);
      controller.tick();
      expect(controller.activeCourse?.id, 'mobile');
      time = DateTime(2026, 10, 27, 16, 45);
      controller.tick();
      expect(controller.activeCourse, isNull);
    });

    test('같은 시간이라도 다른 요일에는 현재 수업으로 선택하지 않는다', () {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 31, 15, 35),
      );
      addTearDown(controller.dispose);
      expect(controller.currentCourses, isEmpty);
      expect(controller.nextSession?.start, DateTime(2026, 11, 2, 10));
    });
  });

  group('출석 코드 확인', () {
    test('현재 수업이 없으면 출석을 처리하지 않는다', () async {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 18),
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      expect(await controller.submitCode('AB'), SubmissionResult.noClass);
    });

    test('영문 두 글자 이외의 입력은 거부하고 틀린 코드도 집계하지 않는다', () async {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 15, 35),
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final mobile = controller.activeCourse!;
      final before = controller.countsFor(mobile);
      for (final code in [
        '',
        'A',
        'ABC',
        '12',
        '1234',
        'A1',
        '가나',
        'ＡＢ',
        'A B',
      ]) {
        expect(
          await controller.submitCode(code),
          SubmissionResult.invalidFormat,
        );
      }
      expect(await controller.submitCode('ZZ'), SubmissionResult.incorrectCode);
      expect(controller.countsFor(mobile), before);
    });

    for (final code in ['AB', 'ab', 'aB', 'Ab']) {
      test('영문 코드 $code는 대소문자를 구분하지 않고 출석한다', () async {
        final controller = AttendanceController(
          clock: () => DateTime(2026, 10, 27, 15, 35),
          delay: Duration.zero,
        );
        addTearDown(controller.dispose);
        expect(await controller.submitCode(code), SubmissionResult.success);
        expect(controller.hasSubmitted(controller.courses.first), isTrue);
        expect(
          controller.countsFor(
            controller.courses.first,
          )[AttendanceStatus.present],
          9,
        );
      });
    }

    test('성공한 출석은 한 번만 집계되고 새로고침 후에도 유지된다', () async {
      var time = DateTime(2026, 10, 27, 15, 35);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final mobile = controller.activeCourse!;
      expect(controller.countsFor(mobile)[AttendanceStatus.present], 8);
      expect(await controller.submitCode(' aB '), SubmissionResult.success);
      expect(controller.countsFor(mobile)[AttendanceStatus.present], 9);
      expect(
        await controller.submitCode('AB'),
        SubmissionResult.alreadySubmitted,
      );
      time = DateTime(2026, 10, 27, 15, 36);
      await controller.refreshCourse(mobile);
      expect(controller.countsFor(mobile)[AttendanceStatus.present], 9);
      expect(controller.lastUpdatedFor(mobile), time);
      expect(controller.hasSubmitted(mobile), isTrue);
    });

    test('전송 중 연속 클릭해도 한 번만 처리된다', () async {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 15, 35),
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final first = controller.submitCode('AB');
      expect(controller.isSubmitting, isTrue);
      expect(await controller.submitCode('AB'), SubmissionResult.busy);
      expect(await first, SubmissionResult.success);
      expect(controller.isSubmitting, isFalse);
      expect(
        controller.countsFor(
          controller.courses.first,
        )[AttendanceStatus.present],
        9,
      );
    });

    test('전송 중 수업이 끝나면 성공 처리하지 않는다', () async {
      var time = DateTime(2026, 10, 27, 16, 44, 59);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final pending = controller.submitCode('AB');
      time = DateTime(2026, 10, 27, 16, 45);
      expect(await pending, SubmissionResult.closed);
      expect(controller.activeCourse, isNull);
      expect(controller.hasSubmitted(controller.courses.first), isFalse);
      expect(
        controller.countsFor(
          controller.courses.first,
        )[AttendanceStatus.present],
        8,
      );
      expect(
        controller.countsFor(
          controller.courses.first,
        )[AttendanceStatus.unrecorded],
        1,
      );
    });

    test('다음 주차 출석은 별도의 수업으로 처리된다', () async {
      var time = DateTime(2026, 10, 27, 15, 35);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      expect(await controller.submitCode('AB'), SubmissionResult.success);
      time = DateTime(2026, 11, 3, 15, 35);
      controller.tick();
      expect(controller.hasSubmitted(controller.courses.first), isFalse);
      expect(await controller.submitCode('AB'), SubmissionResult.success);
      expect(
        controller.countsFor(
          controller.courses.first,
        )[AttendanceStatus.present],
        10,
      );
    });

    test('전송 중 같은 수업의 다른 날짜로 변경해도 출석을 이월하지 않는다', () async {
      var time = DateTime(2026, 10, 27, 15, 35);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final pending = controller.submitCode('AB');
      time = DateTime(2026, 11, 3, 15, 35);
      controller.tick();
      expect(controller.activeCourse?.id, 'mobile');
      expect(await pending, SubmissionResult.closed);
      expect(controller.hasSubmitted(controller.courses.first), isFalse);
      time = DateTime(2026, 10, 27, 15, 35);
      controller.tick();
      expect(controller.hasSubmitted(controller.courses.first), isFalse);
    });

    test('테스트 시간을 과거로 되돌리면 미래의 제출은 집계에서 제외한다', () async {
      var time = DateTime(2026, 10, 27, 15, 35);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final mobile = controller.courses.first;
      expect(await controller.submitCode('AB'), SubmissionResult.success);
      time = DateTime(2026, 10, 20, 15, 35);
      controller.tick();
      expect(controller.hasSubmitted(mobile), isFalse);
      expect(controller.countsFor(mobile)[AttendanceStatus.present], 7);
      time = DateTime(2026, 10, 27, 15, 35);
      controller.tick();
      expect(controller.hasSubmitted(mobile), isTrue);
      expect(controller.countsFor(mobile)[AttendanceStatus.present], 9);
    });
  });

  group('새로고침과 생명주기', () {
    test('실제 시간에서 과거 테스트 시간으로 바꿔도 미래 업데이트를 표시하지 않는다', () async {
      var time = DateTime(2026, 11, 25, 19);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final mobile = controller.courses.first;
      time = DateTime(2026, 10, 27, 15, 35);
      controller.tick();
      expect(controller.lastUpdatedFor(mobile), time);
      await controller.refreshCourse(mobile);
      expect(controller.lastUpdatedFor(mobile), time);
      time = DateTime(2026, 10, 20, 15, 35);
      controller.tick();
      expect(controller.lastUpdatedFor(mobile), time);
    });

    test('같은 과목의 중복 새로고침은 같은 작업을 반환한다', () async {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 15, 35),
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      final mobile = controller.courses.first;
      final before = controller.countsFor(mobile);
      final first = controller.refreshCourse(mobile);
      final second = controller.refreshCourse(mobile);
      expect(identical(first, second), isTrue);
      expect(controller.isRefreshing(mobile), isTrue);
      await first;
      expect(controller.isRefreshing(mobile), isFalse);
      expect(controller.countsFor(mobile), before);
      expect(controller.activeCourse?.id, 'mobile');
    });

    test('학기가 바뀌어도 이전 학기 제출을 새 학기로 합산하지 않는다', () async {
      var time = DateTime(2026, 10, 27, 15, 35);
      final controller = AttendanceController(
        clock: () => time,
        delay: Duration.zero,
      );
      addTearDown(controller.dispose);
      expect(await controller.submitCode('AB'), SubmissionResult.success);
      time = DateTime(2027, 3, 2, 15, 35);
      controller.tick();
      expect(controller.semester.label, '2027년 1학기');
      expect(controller.hasSubmitted(controller.courses.first), isFalse);
      expect(
        controller
            .countsFor(controller.courses.first)
            .values
            .reduce((a, b) => a + b),
        0,
      );
    });

    test('대기 중 controller가 해제되어도 알림 예외를 발생시키지 않는다', () async {
      final controller = AttendanceController(
        clock: () => DateTime(2026, 10, 27, 15, 35),
        delay: Duration.zero,
      );
      final pending = controller.submitCode('AB');
      final refresh = controller.refreshCourse(controller.courses.first);
      controller.dispose();
      expect(await pending, SubmissionResult.closed);
      await refresh;
    });
  });
}
