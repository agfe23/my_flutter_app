# 한국교통대학교 전자출결 UI/UX 개선

대학 모바일 프로그래밍 팀 과제인 **스마트모바일 앱 개선 프로젝트** 중 전자출결을 구현한 Flutter 앱입니다. 직접 설계한 목업의 와인색 테마, 카드 배치, 화면 흐름을 바탕으로 **간편한 출석**과 **편리한 과목별 출결 조회**를 목표로 합니다.

Android와 iOS 프로젝트가 같은 `lib/`의 Dart 코드를 사용합니다. iOS에서도 같은 화면 배치, 출석 코드, 과목 조회와 테스트 시간 기능을 사용하며, 별도의 앱 화면을 중복 구현하지 않습니다.

한국교통대학교 공식 앱이 아닌 **과제용 프로토타입**입니다. 학교 서버에 연결하지 않으며, 화면에 표시되는 수업과 출결은 더미 데이터입니다. 이 앱에서 출석해도 실제 학교 출결에는 반영되지 않습니다.

## 해결하려는 문제

기존 화면의 큰 틀을 유지하면서 출석 과정의 불필요한 탐색과 반복 조작을 줄였습니다.

| 기존 사용 과정의 문제 | 구현한 개선 | 기대 효과 |
| --- | --- | --- |
| 출결을 확인하기 전에 학기를 직접 선택해야 함 | 학기 선택 메뉴를 제거하고 현재 학기를 자동 적용 | 기본 조회 단계를 줄임 |
| 지금 출석할 수업을 목록에서 직접 찾아야 함 | 현재 날짜와 시간에 해당하는 수업을 01 출결 화면에 자동 표시 | 과목을 찾지 않고 코드 입력에 집중 |
| 상세 화면을 새로고침하면 원하는 화면으로 다시 이동해야 함 | 선택한 과목과 상세 화면을 유지한 채 데이터만 갱신 | 반복 탐색과 재선택을 줄임 |

위 효과는 설계 목표이며, 사용자 실험으로 정량 측정한 결과는 아닙니다.

## 구현 범위와 화면 흐름

| 화면 | 주요 기능 |
| --- | --- |
| **01 출결** | 현재 날짜·시간, 현재 수업 자동 표시, 출석 코드 입력·검증·완료 상태 |
| **02 과목 선택** | 현재 학기 과목을 수업 요일과 시작 시간 순서로 표시 |
| **03 출결 상세** | 선택한 과목의 수업 정보, 출석·공결·지각·결석·미입력 집계, 새로고침 |

```mermaid
flowchart LR
    A[하단 출결 탭] --> B[01 출결 · 코드 입력]
    B -->|과목 선택| C[02 과목 목록]
    C -->|과목 선택| D[03 출결 상세]
    D -->|새로고침 · 현재 과목 유지| D
```

- **출석:** 하단 출결 탭 → 01 현재 수업 확인 → 교수의 코드 입력 → 출석 확인.
- **조회:** 01의 과목 선택 → 02에서 과목 선택 → 03 출결 상세.
- 다른 화면에서 하단 **출결** 탭을 눌러도 항상 01로 진입합니다.
- 03의 상단 새로고침 버튼 또는 아래로 당기기를 사용하면 현재 과목과 화면을 유지합니다.
- 수업이 없는 시간에는 안내, 다음 수업, 이번 학기 출결 조회 버튼을 제공합니다.
- 잘못된 코드와 불완전한 입력을 안내하고, 성공한 출석은 같은 수업에 한 번만 집계합니다.

하단에는 **홈·출결·도서관·교통·학식**의 5개 탭이 있습니다. 현재 구현 범위는 출결이며, 나머지 4개 탭은 공통 아이콘과 화면 이름만 표시하는 자리입니다. 홈 탭 자체는 홈 화면을 엽니다. 팀 통합 시 **메인 화면 안에 배치할 출결 버튼**을 01 진입 동작에 연결할 예정입니다.

과거 학기 조회, 시간이 겹치는 수업의 선택, 로그인, 실제 학교 서버 연동은 이번 구현 범위에서 제외합니다.

## 빠르게 출석 시연하기

앱은 기본적으로 **기기의 실제 현재 날짜와 시간**으로 시작합니다. 수업 시간이 아니어도 앱 안에서 테스트 날짜·시간을 지정할 수 있습니다.

1. 출결 화면 오른쪽 위 **시계 아이콘**을 누릅니다.
2. 날짜·시간을 직접 선택하거나 **예시 시간으로 맞추기 · 화 15:35**를 누릅니다.
3. **이 시간으로 테스트**를 누릅니다. 예시 시각은 **2026-10-27 15:35**, 현재 과목은 **모바일앱프로그래밍**입니다.
4. 코드 **AB**를 입력하고 **출석 확인하기**를 누릅니다.
5. **과목 선택 → 모바일앱프로그래밍**에서 출석 집계를 확인합니다. 예시 시각의 초기 출석은 8회이며, 제출 후 9회가 됩니다.
6. 새로고침 후에도 같은 과목과 출석 9회가 유지되는지 확인합니다.
7. 상단 테스트 안내의 **해제** 또는 시계 설정의 **현재 시간으로 돌아가기**를 눌러 실제 시각으로 복귀합니다.

코드는 **영문 알파벳 2글자**이며 대소문자를 구분하지 않습니다. `AB`, `ab`, `Ab`를 같은 코드로 처리합니다. `ZZ`는 오답, 빈 입력이나 1글자는 형식 오류를 확인하는 예입니다. 입력창은 영문 알파벳만 최대 2글자까지 받습니다.

테스트 시각은 고정되며 자동으로 흐르지 않습니다. 기기의 실제 시계는 변경하지 않습니다. 테스트 시각을 해제해도 이미 제출한 더미 기록은 유지됩니다.

## 더미 데이터와 초기화

출석 기록과 테스트 시각은 앱 메모리에만 보관합니다. 화면 이동과 새로고침에서는 유지되지만 **앱 완전 재시작 또는 Hot Restart** 시 초기화됩니다. 저장소·데이터베이스에 실제 출결 기록을 저장하는 기능은 없습니다.

| 과목 | 매주 수업 시간 | 강의실 |
| --- | --- | --- |
| 컴퓨터네트워크 | 월 10:00–11:15 | IT융합관 305호 |
| 모바일앱프로그래밍 | 화 15:30–16:45 | IT융합관 302호 |
| 운영체제 | 수 09:00–10:15 | IT융합관 303호 |
| 자료구조 | 목 13:30–14:45 | IT융합관 304호 |

수업 판정에는 시작 시각을 포함하고 종료 시각은 제외합니다. 예를 들어 화요일 15:30에는 모바일앱프로그래밍이 표시되고, 16:45부터는 진행 중인 수업으로 보지 않습니다.

학기와 기록은 다음 **시험용 규칙**을 사용합니다. 학교의 공식 학사일정이나 실제 출결 규정이 아닙니다.

- 3~8월은 1학기, 9~2월은 2학기입니다. 1~2월에는 전년도 2학기를 적용합니다.
- 모의 수업은 3월 1일 또는 9월 1일부터 16주 동안 생성합니다.
- 앱 시작 전의 지난 수업에는 예시 기록을 채웁니다. 앱 시작 후 코드 입력 없이 끝난 수업은 미입력으로 남습니다.
- 실제 서비스와 연결할 때는 학기, 시간표, 코드 검증, 출결 집계 자료를 학교 서버 기준으로 교체해야 합니다.

보고서·목업 원본 PDF와 실제 학생의 학번·출결 기록 등 개인정보가 포함된 자료는 저장소에 추가하지 않습니다. 시연 자료를 공유할 때도 더미 데이터만 사용합니다.

## 개발 환경

Android는 Windows 11과 Android 에뮬레이터에서 검증했습니다. iOS용 Xcode 프로젝트도 포함했으며, iOS 빌드와 실행에는 Mac이 필요합니다. 두 플랫폼 모두 팀과 같은 Flutter 버전을 사용합니다.

| 항목 | 프로젝트 기준 |
| --- | --- |
| Flutter | **3.50.1 stable** |
| Dart | **3.14.0**, 해당 Flutter SDK에 포함 |
| Android Gradle Plugin | **9.3.1** — 팀 최소 요구 9.1.1 충족 |
| Gradle wrapper | **9.5.0** |
| Java 소스/바이트코드 대상 | 17 |
| 검증한 빌드 JDK | Android Studio 내장 JDK 25.0.4 |
| Android compile/target SDK | Flutter 기본값, 현재 API 36 |
| NDK | `ndkVersion = flutter.ndkVersion`, 현재 28.2.13676358 |
| 검증한 에뮬레이터 | Android API 37 |
| iOS 최소 버전 | **iOS 15.0** — Flutter 3.50.1 생성 설정 |
| iOS 개발 도구 | macOS, Xcode, iOS Simulator 또는 iPhone |
| iOS 네이티브 의존성 관리 | Flutter 기본 Swift Package Manager |

AGP는 [android/settings.gradle.kts](android/settings.gradle.kts), Gradle은 [gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties), NDK는 [android/app/build.gradle.kts](android/app/build.gradle.kts)에서 확인합니다. NDK 버전을 앱 설정에 별도로 고정하지 않고 Flutter 기본값을 따릅니다. Dart 패키지 재현을 위해 `pubspec.lock`도 함께 관리합니다.

Windows에서는 iOS 앱을 빌드하거나 iOS Simulator를 실행할 수 없습니다. iOS 프로젝트 설정과 공통 Dart 코드를 준비한 상태이며, **실제 iOS 빌드·시뮬레이터·실기기 확인은 Mac에서 진행해야 합니다.** Windows 데스크톱 앱을 개발하기 위한 Visual Studio는 Android 테스트에 필요하지 않습니다. [Flutter iOS 개발 환경 안내](https://docs.flutter.dev/platform-integration/ios/setup), [지원 플랫폼](https://docs.flutter.dev/reference/supported-platforms)

## 설치와 실행

### 1. Android 개발 도구 준비

- Git을 설치합니다. `git --version`으로 이미 설치되어 있는지 먼저 확인합니다.
- Flutter **3.50.1** SDK를 설치하고 해당 SDK의 `bin` 폴더를 사용자 PATH에 추가합니다. Dart는 별도로 설치할 필요가 없습니다.
- Android Studio에서 Android SDK, SDK 도구, Android Emulator를 설치합니다.
- Device Manager에서 가상 기기를 만들고 실행하여 Android 홈 화면이 나타날 때까지 기다립니다.

PATH를 변경했다면 PowerShell을 새로 열어 확인합니다.

```powershell
git --version
flutter --version
flutter doctor -v
```

`flutter doctor -v`의 Android toolchain 항목을 먼저 해결합니다. SDK 라이선스 관련 안내가 있으면 설치된 도구의 안내에 따라 승인합니다. 팀 합의 없이 Flutter 버전을 변경하지 않습니다.

### 2. 저장소 복제와 의존성 설치

원하는 개발 폴더에서 다음 명령을 실행합니다. 이미 복제한 저장소가 있다면 해당 폴더를 열어 사용합니다.

```powershell
git clone https://github.com/agfe23/my_flutter_app.git
Set-Location my_flutter_app
flutter pub get
flutter devices
```

### 3. Android에서 실행

`flutter devices` 결과에 표시된 **Android 기기 ID**를 사용합니다. 아래의 `emulator-5554`는 예시이므로 실제 ID가 다르면 바꿉니다.

```powershell
flutter run -d emulator-5554
```

앱 실행 중에는 해당 PowerShell을 열어 둡니다. 코드를 저장한 뒤 같은 터미널에서 다음 키를 누를 수 있습니다.

| 키 | 동작 |
| --- | --- |
| `r` | Hot Reload: 변경한 UI를 반영하고 현재 상태 유지 |
| `R` — `Shift` + `r` | Hot Restart: 앱을 다시 시작하여 테스트 시각과 더미 출석 기록 초기화 |
| `q` | 실행 종료 |

Android 기기가 목록에 없으면 Device Manager에서 에뮬레이터를 먼저 켭니다. `flutter` 명령을 찾지 못하면 PATH에 등록한 SDK의 `bin` 경로를 확인하고 PowerShell을 다시 엽니다. 에뮬레이터 자체가 종료되는 문제는 앱 오류와 구분해 확인합니다.

첫 Android 빌드에서 NDK 자동 설치가 실패하면 Android Studio의 **SDK Manager → SDK Tools → Show Package Details → NDK (Side by side)**에서 **28.2.13676358**을 설치합니다. 필요한 SDK 구성요소를 설치하되 프로젝트의 `flutter.ndkVersion` 설정은 유지합니다.

### 4. Mac에서 iOS 실행

Mac에 **Flutter 3.50.1**과 Xcode를 설치합니다. Xcode에서 iOS 플랫폼과 시뮬레이터를 준비한 뒤, Mac 터미널에서 아래 명령을 실행합니다. Xcode를 다른 경로에 설치했다면 첫 명령의 경로를 바꿉니다.

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license
xcodebuild -downloadPlatform iOS
flutter --version
flutter doctor -v
```

라이선스 내용은 화면에서 확인한 뒤 승인합니다. `flutter doctor -v`의 Xcode 관련 항목을 해결한 다음 앱을 실행합니다. 세부 설치 절차는 [Flutter 공식 iOS 설정 안내](https://docs.flutter.dev/platform-integration/ios/setup)를 참고합니다.

처음 내려받는 Mac에서는 원하는 작업 폴더에서 다음 명령을 실행합니다.

```bash
git clone https://github.com/agfe23/my_flutter_app.git
cd my_flutter_app
flutter pub get
```

이미 복제한 경우에는 프로젝트 폴더에서 자신의 변경을 정리한 후 `git pull --ff-only`와 `flutter pub get`으로 갱신합니다.

Xcode 27에서는 다음 명령으로 **Device Hub**를 열고 iPhone 시뮬레이터를 실행합니다. Xcode 26 이하에서는 대신 `open -a Simulator`를 사용합니다.

```bash
open -a DeviceHub
flutter devices
```

아래 `IOS_DEVICE_ID`를 `flutter devices`에 표시된 **iOS 시뮬레이터의 실제 ID**로 바꿉니다. 시뮬레이터가 목록에 없으면 먼저 기기를 부팅합니다.

```bash
flutter run -d "IOS_DEVICE_ID"
```

앱 이름은 **전자출결**입니다. 실행 후 **시계 아이콘 → 예시 시간으로 맞추기 → 이 시간으로 테스트 → 코드 AB** 순서로 Android와 같은 과정을 확인할 수 있습니다. 터미널의 `R`(`Shift` + `r`)로 재시작하면 테스트 시각과 제출 기록도 초기화됩니다.

Mac에서 iOS 시뮬레이터용 빌드만 확인하려면 다음 명령을 사용합니다.

```bash
flutter build ios --simulator --debug
```

이 프로젝트는 Flutter 기본 **Swift Package Manager** 설정을 사용합니다. 현재는 별도의 네이티브 플러그인이 없어 `Podfile`이나 `pod install` 단계가 필요하지 않습니다. 이후 CocoaPods만 지원하는 네이티브 플러그인을 추가한다면 해당 플러그인과 Flutter의 안내를 따릅니다. [Swift Package Manager 안내](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

### 5. 실제 iPhone에서 확인

Mac에 iPhone을 연결하고 기기의 **이 컴퓨터 신뢰**와 **개발자 모드** 설정을 완료합니다. 프로젝트 폴더에서 다음 명령으로 Xcode 작업 공간을 엽니다.

```bash
open ios/Runner.xcworkspace
```

Xcode의 **Runner 대상 → Signing & Capabilities**에서 **Automatically manage signing**을 켜고, 본인의 Apple 계정에 연결된 **Team**을 선택합니다. 기본 Bundle Identifier는 `com.example.myFlutterApp`이므로, 필요하면 본인이 사용할 수 있는 고유한 식별자로 바꿉니다. 이후 `flutter devices`에서 확인한 iPhone ID로 `flutter run -d "IOS_DEVICE_ID"`를 실행합니다.

인증서와 서명 설정은 개발자의 Mac에서 관리합니다. 이 저장소에는 Apple 계정 정보나 서명 자료를 포함하지 않으며, App Store 배포는 이번 작업 범위에 포함하지 않습니다. 기기 준비와 서명은 [Flutter의 실제 iOS 기기 설정 안내](https://docs.flutter.dev/platform-integration/ios/setup)를 참고합니다.

## 검증

**2026-11-25 검증 결과:** `flutter analyze` 오류 없음, `flutter test` **31개 통과**(데이터 20개·화면 11개, iOS 플랫폼 설정 테스트 2개 포함). iOS 설정의 XML과 앱 아이콘 리소스 참조도 확인했습니다. Android 디버그 APK 빌드와 에뮬레이터의 소문자 코드 제출·출석 완료·요일순 과목 목록·화면 이동은 앞선 구현에서 확인했습니다.

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

생성한 APK 위치는 `build/app/outputs/flutter-apk/app-debug.apk`입니다.

자동 테스트는 수업 시작·종료 경계, 학기·날짜 변경, 영문 코드 형식과 대소문자, 중복 제출, 화면 이동, 선택 과목 유지 새로고침, 테스트 시각 적용·해제, Android 뒤로가기를 확인합니다. 320폭 화면, 글자 2배 확대, 키보드가 열린 상태의 출석 흐름도 포함합니다.

iOS 플랫폼 설정을 사용하는 위젯 테스트에서는 공통 출석·상세·새로고침 흐름과 iPhone 크기의 안전 영역·키보드 상황을 확인합니다. 이는 Windows에서 수행할 수 있는 Flutter 위젯 테스트이며, **Xcode 빌드나 실제 iOS 실행 검증을 대신하지 않습니다.** Mac에서 위의 iOS 빌드·실행 절차를 별도로 확인해야 합니다.

## 코드 구조와 팀 통합

| 파일 | 역할 |
| --- | --- |
| [lib/main.dart](lib/main.dart) | 앱 시작, 한국어 지역화, 테마 연결 |
| [lib/app_theme.dart](lib/app_theme.dart) | 색상, 버튼, 입력창, 하단 바 스타일 |
| [lib/attendance_shell.dart](lib/attendance_shell.dart) | 하단 탭, 01→02→03 이동, 시계와 공통 출결 상태 유지 |
| [lib/attendance_screens.dart](lib/attendance_screens.dart) | 세 출결 화면의 배치와 코드 입력 UI |
| [lib/attendance_data.dart](lib/attendance_data.dart) | 더미 시간표, 코드 검증, 학기·출석·집계 로직 |
| [lib/testing_clock_sheet.dart](lib/testing_clock_sheet.dart) | 수동 날짜·시간 설정과 예시 시간 버튼 |
| [ios/Runner](ios/Runner) | iOS 앱 이름·한국어 설정, AppDelegate·SceneDelegate, 실행 리소스 |
| [ios/Runner.xcworkspace](ios/Runner.xcworkspace) | Mac의 Xcode에서 여는 iOS 작업 공간 |
| [test/attendance_data_test.dart](test/attendance_data_test.dart) | 수업 경계와 출결 데이터 로직 검증 |
| [test/attendance_flow_test.dart](test/attendance_flow_test.dart) | 화면 이동, 출석, 시간 설정과 작은 화면 검증 |

시간표는 `attendance_data.dart`의 `mockCourses`, 출석 코드는 `demoCode = 'AB'`, 색상은 `app_theme.dart`의 `AppColors`에서 수정합니다. 코드 규칙을 유지하려면 새 코드도 영문 2글자로 지정합니다. 예시 데이터를 바꾸면 해당 데이터를 기대하는 테스트도 함께 조정합니다.

팀 앱에 통합할 때는 현재 자리만 마련된 홈·도서관·교통·학식 화면을 각 팀원의 구현으로 교체합니다. **메인 화면 내부의 출결 버튼**과 **하단 출결 탭**은 모두 01 출결 화면으로 연결하고, 홈 탭은 홈 화면 이동을 유지합니다. 공통 하단 바를 중복으로 만들지 않고, 화면 이동 시 출결 상태가 유지되도록 현재 `AttendanceShell`의 상태 관리와 진입 동작을 연결합니다.

## 협업

작업 전 팀의 최신 변경을 확인하고, 기능별 브랜치에서 작은 단위로 수정합니다. 변경 사항에는 실행 방법과 확인한 테스트를 함께 남깁니다. Flutter·AGP·Gradle 및 패키지 버전 변경은 팀과 먼저 합의합니다.

PC별 SDK 경로, 빌드 결과물, IDE 캐시와 Flutter SDK 자체는 커밋하지 않습니다. 공통 소스·설정·테스트와 `pubspec.lock`을 공유하여 다른 팀원도 같은 환경으로 실행할 수 있도록 유지합니다.
