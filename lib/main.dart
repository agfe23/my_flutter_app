import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'attendance_shell.dart';

void main() {
  runApp(const MyFlutterApp());
}

class MyFlutterApp extends StatelessWidget {
  const MyFlutterApp({
    super.key,
    this.clock,
    this.enableTicker = true,
    this.mockDelay = const Duration(milliseconds: 450),
  });

  // 자동 테스트에서는 시계와 대기 시간을 주입하여 같은 상황을 재현합니다.
  final DateTime Function()? clock;
  final bool enableTicker;
  final Duration mockDelay;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한국교통대학교 전자출결',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AttendanceShell(
        clock: clock,
        enableTicker: enableTicker,
        mockDelay: mockDelay,
      ),
    );
  }
}
