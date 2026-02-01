# Inter 폰트 추가 가이드

## 현재 상태
- 프로젝트는 **Roboto 기본 폰트**로 설정되어 있습니다
- 즉시 실행 가능합니다

## Inter 폰트 추가하기 (선택사항)

### 단계 1: Inter 폰트 다운로드
https://fonts.google.com/download?family=Inter 에서 다운로드

### 단계 2: 폰트 파일 준비
다운로드한 폴더에서 다음 4개 파일 추출:
- Inter-Regular.ttf
- Inter-Medium.ttf
- Inter-SemiBold.ttf
- Inter-Bold.ttf

### 단계 3: 폴더에 추가
프로젝트 루트에 폴더 구조를 만듭니다:
```
your_project/
├── assets/
│   └── fonts/
│       ├── Inter-Regular.ttf
│       ├── Inter-Medium.ttf
│       ├── Inter-SemiBold.ttf
│       └── Inter-Bold.ttf
```

### 단계 4: pubspec.yaml 수정
```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### 단계 5: ff_theme.dart 수정
```dart
// ff_theme.dart의 첫 부분을 이렇게 수정:
class FFTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',  // ← 이 라인 추가
      // ... 나머지는 동일
```

### 단계 6: 완료
```bash
flutter pub get
flutter run
```

---

## 더 쉬운 방법 (Google Fonts 패키지 사용)
pubspec.yaml에 추가:
```yaml
dependencies:
  google_fonts: ^6.0.0
```

그 후 ff_theme.dart에서:
```dart
import 'package:google_fonts/google_fonts.dart';

class FFTheme {
  static ThemeData get light {
    return ThemeData(
      fontFamily: GoogleFonts.inter().fontFamily,
      // ... 나머지
```

---

## 현재 기본값
- **폰트**: Roboto (Flutter 기본)
- **상태**: 완벽하게 작동합니다
- **Inter 필요 시**: 위의 단계를 따르세요
