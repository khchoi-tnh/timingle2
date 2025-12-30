# 다국어(i18n) 및 시간대(Timezone) 전략

**목표**: timingle을 글로벌 서비스로 확장 가능하도록 설계

---

## 🌍 지원 언어 (Phase별 확장)

### Phase 1 (MVP): 한국어 우선
- **ko** (한국어) - 기본 언어
- **en** (영어) - 2차 지원

### Phase 2 (글로벌 확장):
- **ja** (일본어)
- **zh-CN** (중국어 간체)
- **zh-TW** (중국어 번체)
- **es** (스페인어)
- **pt** (포르투갈어)
- **fr** (프랑스어)
- **de** (독일어)

---

## 🕐 시간대(Timezone) 처리 원칙

### 핵심 원칙: "모든 시간은 UTC로 저장, 사용자 시간대로 표시"

#### 1. 데이터베이스 저장
- **모든 TIMESTAMP는 UTC로 저장**
- PostgreSQL: `timestamp with time zone` 사용 (권장) 또는 `timestamp` + 애플리케이션 레벨 UTC 변환
- ScyllaDB: `TIMESTAMP` 타입 (UTC 기준)

```sql
-- PostgreSQL 설정
SET timezone = 'UTC'; -- 서버 기본 시간대를 UTC로

CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  -- ...
  created_at TIMESTAMPTZ DEFAULT NOW(), -- WITH TIME ZONE
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  -- ...
  start_time TIMESTAMPTZ NOT NULL,  -- UTC로 저장됨
  end_time TIMESTAMPTZ NOT NULL,
  -- ...
);
```

#### 2. API 입출력
- **입력**: 클라이언트는 RFC3339 형식(ISO 8601)으로 시간대 포함하여 전송
- **출력**: 서버는 UTC로 응답, 클라이언트가 로컬 시간대로 변환

```json
// 클라이언트 → 서버 (한국 사용자)
{
  "start_time": "2025-01-15T09:00:00+09:00",  // KST (UTC+9)
  "end_time": "2025-01-15T10:00:00+09:00"
}

// 서버 → 클라이언트 (UTC로 저장됨)
{
  "start_time": "2025-01-15T00:00:00Z",  // UTC
  "end_time": "2025-01-15T01:00:00Z"
}

// Flutter 앱이 한국 사용자에게 표시
"2025년 1월 15일 오전 9시 ~ 오전 10시"  // 로컬 시간대로 자동 변환
```

#### 3. 사용자 시간대 저장
```sql
ALTER TABLE users ADD COLUMN timezone VARCHAR(50) DEFAULT 'UTC';

-- 예시 데이터
-- 한국 사용자: 'Asia/Seoul'
-- 미국 동부: 'America/New_York'
-- 일본: 'Asia/Tokyo'
```

#### 4. Go 백엔드 처리
```go
// internal/models/event.go
type CreateEventRequest struct {
    Title       string `json:"title" binding:"required"`
    Description string `json:"description"`
    StartTime   string `json:"start_time" binding:"required"` // RFC3339
    EndTime     string `json:"end_time" binding:"required"`   // RFC3339
    Location    string `json:"location"`
    ParticipantIDs []int64 `json:"participant_ids"`
}

// internal/services/event_service.go
func (s *EventService) CreateEvent(creatorID int64, req *models.CreateEventRequest) (*models.EventWithParticipants, error) {
    // RFC3339 파싱 (시간대 정보 자동 처리)
    startTime, err := time.Parse(time.RFC3339, req.StartTime)
    if err != nil {
        return nil, fmt.Errorf("invalid start_time format")
    }

    // time.Time은 내부적으로 UTC로 저장됨
    // PostgreSQL에 저장 시 자동으로 UTC로 변환
    event := &models.Event{
        StartTime: startTime,  // UTC로 저장
        EndTime:   endTime,
        // ...
    }

    // ...
}

// 출력 시에도 time.Time이 JSON 직렬화되면 자동으로 RFC3339 UTC 형식
```

#### 5. Flutter 앱 처리
```dart
// lib/core/utils/timezone_helper.dart
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  // 사용자의 현재 시간대 가져오기
  static String getUserTimezone() {
    return DateTime.now().timeZoneName; // 예: "KST"
  }

  // UTC 시간을 로컬 시간대로 변환
  static DateTime utcToLocal(DateTime utcTime) {
    return utcTime.toLocal();
  }

  // 로컬 시간을 UTC로 변환 (서버 전송용)
  static DateTime localToUtc(DateTime localTime) {
    return localTime.toUtc();
  }

  // RFC3339 형식으로 포맷 (서버 전송용)
  static String toRFC3339(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  // 사용자 친화적 표시 (로컬 시간대)
  static String formatForUser(DateTime utcTime, String locale) {
    final local = utcTime.toLocal();
    // 한국어: "2025년 1월 15일 오전 9시"
    // 영어: "Jan 15, 2025 9:00 AM"
    return DateFormat.yMMMd(locale).add_jm().format(local);
  }
}

// 사용 예시
final event = Event(
  startTime: DateTime.parse("2025-01-15T00:00:00Z"), // 서버에서 받은 UTC
);

// 화면에 표시
Text(TimezoneHelper.formatForUser(event.startTime, 'ko')); // "2025년 1월 15일 오전 9시"

// 서버에 전송
final createRequest = CreateEventRequest(
  startTime: TimezoneHelper.toRFC3339(selectedDateTime), // "2025-01-15T00:00:00Z"
);
```

---

## 🌐 다국어(i18n) 처리

### Backend (Go)

#### 1. 다국어 메시지 파일
```bash
# backend/locales/ko.json
{
  "errors.invalid_phone": "전화번호 형식이 올바르지 않습니다",
  "errors.user_not_found": "사용자를 찾을 수 없습니다",
  "errors.event_not_found": "이벤트를 찾을 수 없습니다",
  "errors.access_denied": "접근 권한이 없습니다",
  "success.event_created": "이벤트가 생성되었습니다",
  "success.event_updated": "이벤트가 수정되었습니다"
}

# backend/locales/en.json
{
  "errors.invalid_phone": "Invalid phone number format",
  "errors.user_not_found": "User not found",
  "errors.event_not_found": "Event not found",
  "errors.access_denied": "Access denied",
  "success.event_created": "Event created successfully",
  "success.event_updated": "Event updated successfully"
}
```

#### 2. i18n 패키지 (Go)
```bash
go get -u github.com/nicksnyder/go-i18n/v2/i18n
go get -u golang.org/x/text/language
```

```go
// pkg/utils/i18n.go
package utils

import (
    "github.com/nicksnyder/go-i18n/v2/i18n"
    "golang.org/x/text/language"
    "gopkg.in/yaml.v2"
)

var bundle *i18n.Bundle

func InitI18n() {
    bundle = i18n.NewBundle(language.Korean) // 기본 언어
    bundle.RegisterUnmarshalFunc("json", json.Unmarshal)

    // 언어 파일 로드
    bundle.MustLoadMessageFile("locales/ko.json")
    bundle.MustLoadMessageFile("locales/en.json")
}

func Translate(lang, messageID string) string {
    localizer := i18n.NewLocalizer(bundle, lang)
    msg, _ := localizer.Localize(&i18n.LocalizeConfig{
        MessageID: messageID,
    })
    return msg
}
```

#### 3. API 응답에 적용
```go
// internal/middleware/i18n.go
package middleware

import (
    "github.com/gin-gonic/gin"
    "github.com/yourusername/timingle/pkg/utils"
)

func I18nMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Accept-Language 헤더에서 언어 추출
        lang := c.GetHeader("Accept-Language")
        if lang == "" {
            lang = "ko" // 기본값
        }

        // 지원되는 언어인지 확인
        supportedLangs := []string{"ko", "en", "ja", "zh", "es"}
        if !contains(supportedLangs, lang) {
            lang = "ko"
        }

        c.Set("lang", lang)
        c.Next()
    }
}

// 핸들러에서 사용
func (h *EventHandler) GetEvent(c *gin.Context) {
    lang := c.GetString("lang")

    event, err := h.eventService.GetEvent(eventID, userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": utils.Translate(lang, "errors.event_not_found"),
        })
        return
    }

    c.JSON(http.StatusOK, event)
}
```

### Frontend (Flutter)

#### 1. flutter_localizations 패키지
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  easy_localization: ^3.0.3  # 또는 flutter_i18n
```

#### 2. 다국어 리소스 파일
```json
// assets/translations/ko.json
{
  "app_name": "timingle",
  "login": {
    "title": "로그인",
    "phone_placeholder": "전화번호를 입력하세요",
    "code_placeholder": "인증 코드",
    "submit": "로그인"
  },
  "timingle": {
    "title": "Timingle",
    "filter_all": "전체",
    "filter_upcoming": "예정",
    "filter_done": "완료",
    "no_events": "약속이 없습니다",
    "create_event": "새 약속 만들기"
  },
  "event": {
    "title": "이벤트",
    "status_proposed": "제안됨",
    "status_confirmed": "확정됨",
    "status_canceled": "취소됨",
    "status_done": "완료",
    "participants": "참여자",
    "location": "장소",
    "time": "시간"
  },
  "errors": {
    "network_error": "네트워크 오류가 발생했습니다",
    "invalid_phone": "전화번호 형식이 올바르지 않습니다",
    "login_failed": "로그인에 실패했습니다"
  }
}

// assets/translations/en.json
{
  "app_name": "timingle",
  "login": {
    "title": "Login",
    "phone_placeholder": "Enter your phone number",
    "code_placeholder": "Verification code",
    "submit": "Login"
  },
  "timingle": {
    "title": "Timingle",
    "filter_all": "All",
    "filter_upcoming": "Upcoming",
    "filter_done": "Done",
    "no_events": "No events",
    "create_event": "Create Event"
  },
  "event": {
    "title": "Event",
    "status_proposed": "Proposed",
    "status_confirmed": "Confirmed",
    "status_canceled": "Canceled",
    "status_done": "Done",
    "participants": "Participants",
    "location": "Location",
    "time": "Time"
  },
  "errors": {
    "network_error": "Network error occurred",
    "invalid_phone": "Invalid phone number format",
    "login_failed": "Login failed"
  }
}
```

#### 3. Flutter 앱 설정
```dart
// main.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('ko', 'KR'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'timingle',
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: LoginPage(),
    );
  }
}
```

#### 4. 사용 예시
```dart
// lib/features/timingle/presentation/pages/timingle_page.dart
import 'package:easy_localization/easy_localization.dart';

class TiminglePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('timingle.title'.tr()), // "Timingle" (한국어) / "Timingle" (영어)
      ),
      body: Column(
        children: [
          // 필터 탭
          TabBar(
            tabs: [
              Tab(text: 'timingle.filter_all'.tr()),      // "전체" / "All"
              Tab(text: 'timingle.filter_upcoming'.tr()), // "예정" / "Upcoming"
              Tab(text: 'timingle.filter_done'.tr()),     // "완료" / "Done"
            ],
          ),
          // 이벤트 리스트
          Expanded(
            child: eventsState.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Text('timingle.no_events'.tr()), // "약속이 없습니다"
                  );
                }
                return EventList(events: events);
              },
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('errors.network_error'.tr()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEvent(context),
        child: Icon(Icons.add),
        tooltip: 'timingle.create_event'.tr(), // "새 약속 만들기"
      ),
    );
  }
}

// 시간 표시 (로컬 시간대)
class EventCard extends StatelessWidget {
  final Event event;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString(); // "ko_KR", "en_US"

    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          TimezoneHelper.formatForUser(event.startTime, locale),
          // 한국어: "2025년 1월 15일 오전 9시"
          // 영어: "Jan 15, 2025 9:00 AM"
        ),
      ),
    );
  }
}
```

---

## 🗄️ 데이터베이스 마이그레이션 업데이트

### PostgreSQL 업데이트
```sql
-- migrations/001_create_users_table.sql에 추가
ALTER TABLE users ADD COLUMN timezone VARCHAR(50) DEFAULT 'UTC';
ALTER TABLE users ADD COLUMN language VARCHAR(10) DEFAULT 'ko';

CREATE INDEX idx_users_timezone ON users(timezone);
CREATE INDEX idx_users_language ON users(language);

-- 예시 데이터
-- timezone: 'Asia/Seoul', 'America/New_York', 'Europe/London', 'Asia/Tokyo'
-- language: 'ko', 'en', 'ja', 'zh-CN', 'es'
```

### User 모델 업데이트
```go
// internal/models/user.go
type User struct {
    ID              int64     `json:"id" db:"id"`
    Phone           string    `json:"phone" db:"phone"`
    Name            string    `json:"name" db:"name"`
    Email           string    `json:"email" db:"email"`
    ProfileImageURL string    `json:"profile_image_url" db:"profile_image_url"`
    Region          string    `json:"region" db:"region"`
    Interests       []string  `json:"interests" db:"interests"`
    Timezone        string    `json:"timezone" db:"timezone"` // 추가: 'Asia/Seoul'
    Language        string    `json:"language" db:"language"` // 추가: 'ko', 'en'
    Role            string    `json:"role" db:"role"`
    CreatedAt       time.Time `json:"created_at" db:"created_at"`
    UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}
```

---

## 📱 Flutter 시간대 패키지
```yaml
# pubspec.yaml
dependencies:
  timezone: ^0.9.2
  intl: ^0.19.0
```

```dart
// lib/core/utils/timezone_init.dart
import 'package:timezone/data/latest.dart' as tz;

void initTimezone() {
  tz.initializeTimeZones();
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시간대 초기화
  initTimezone();

  // 다국어 초기화
  await EasyLocalization.ensureInitialized();

  runApp(MyApp());
}
```

---

## 🎯 체크리스트

### Backend
- [ ] PostgreSQL에 `timezone`, `language` 컬럼 추가
- [ ] 모든 TIMESTAMP는 UTC로 저장 (`TIMESTAMPTZ`)
- [ ] API 입력: RFC3339 형식 파싱
- [ ] API 출력: UTC로 응답
- [ ] i18n 패키지 설치 및 설정
- [ ] `locales/ko.json`, `locales/en.json` 생성
- [ ] `Accept-Language` 헤더 처리 미들웨어

### Frontend
- [ ] `easy_localization` 패키지 설치
- [ ] `assets/translations/` 디렉토리 생성
- [ ] 모든 UI 텍스트를 `.tr()` 사용
- [ ] 시간 표시 시 `toLocal()` + `DateFormat` 사용
- [ ] 사용자 설정에서 언어/시간대 변경 가능하도록

### 테스트
- [ ] 한국 사용자(KST)와 미국 사용자(EST)가 같은 이벤트를 생성/조회 시 시간 일치 확인
- [ ] 언어 변경 시 UI 텍스트 즉시 변경 확인
- [ ] API 응답이 사용자 언어에 맞는 에러 메시지 반환 확인

---

**글로벌 서비스를 위한 필수 고려사항 완료!** 🌍
