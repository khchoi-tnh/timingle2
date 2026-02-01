# Google Calendar 연동 설정 가이드

timingle 앱에서 Google Calendar와 연동하기 위한 설정 가이드입니다.

## 1. 사전 요구사항

Google OAuth 기본 설정이 완료되어 있어야 합니다.
- [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) 참조

## 2. Google Cloud Console 설정

### 2.1 Calendar API 활성화

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. **APIs & Services** → **Library**
3. "Google Calendar API" 검색
4. **Enable** 클릭

### 2.2 OAuth 동의 화면에 Calendar Scope 추가

1. **APIs & Services** → **OAuth consent screen**
2. **Edit App** 클릭
3. **Scopes** 단계에서 **Add or remove scopes** 클릭
4. 다음 scope 추가:
   - `https://www.googleapis.com/auth/calendar` (전체 읽기/쓰기)
   - 또는 `https://www.googleapis.com/auth/calendar.events` (이벤트만)
5. **Save and Continue**

### 2.3 Client Secret 확인

1. **APIs & Services** → **Credentials**
2. Web 클라이언트 선택
3. **Client secret** 값 복사

## 3. 환경변수 설정

### Backend (.env)
```bash
# 기존 Google OAuth 설정
GOOGLE_CLIENT_ID_AND=xxx.apps.googleusercontent.com  # Android
GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com  # iOS
GOOGLE_CLIENT_ID_WEB=xxx.apps.googleusercontent.com  # Web

# Calendar 연동용 추가 설정
GOOGLE_CLIENT_SECRET=your-client-secret-here
```

### run.sh 업데이트
```bash
export GOOGLE_CLIENT_ID_AND=xxx.apps.googleusercontent.com
export GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com
export GOOGLE_CLIENT_ID_WEB=xxx.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=your-client-secret-here
```

## 4. 데이터베이스 마이그레이션

Calendar 연동을 위해 새로운 마이그레이션을 실행해야 합니다:

```bash
# PostgreSQL에 접속하여 실행
psql -U timingle -d timingle

# 마이그레이션 파일 실행
\i migrations/006_add_oauth_tokens.sql
\i migrations/007_add_google_calendar_id.sql
```

### 마이그레이션 내용

**006_add_oauth_tokens.sql** - OAuth 토큰 저장 필드:
```sql
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS access_token TEXT;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS refresh_token TEXT;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS token_expiry TIMESTAMPTZ;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS scopes TEXT[];
```

**007_add_google_calendar_id.sql** - 이벤트-캘린더 연동 ID:
```sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS google_calendar_id VARCHAR(255);
```

## 5. API 엔드포인트

### 5.1 Calendar 권한 포함 로그인

**POST /api/v1/auth/google/calendar**

기존 Google 로그인에 Calendar scope를 포함하여 로그인합니다.

Request:
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "access_token": "ya29.a0AfH6SMB...",
  "refresh_token": "1//0eXXXX...",
  "platform": "android"
}
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "email": "user@gmail.com",
    "name": "User Name"
  }
}
```

### 5.2 Calendar 연동 상태 확인

**GET /api/v1/calendar/status**

현재 사용자의 Calendar 연동 상태를 확인합니다.

Response:
```json
{
  "has_calendar_access": true
}
```

### 5.3 Google Calendar 이벤트 조회

**GET /api/v1/calendar/events**

Query Parameters:
- `start_time`: 시작 시간 (RFC3339, 선택)
- `end_time`: 종료 시간 (RFC3339, 선택)

Response:
```json
{
  "events": [
    {
      "id": "abc123",
      "summary": "미팅",
      "description": "팀 미팅",
      "location": "회의실 A",
      "start_time": "2024-01-15T10:00:00+09:00",
      "end_time": "2024-01-15T11:00:00+09:00",
      "html_link": "https://calendar.google.com/event?eid=xxx"
    }
  ],
  "start_time": "2024-01-01T00:00:00+09:00",
  "end_time": "2024-01-31T23:59:59+09:00",
  "count": 1
}
```

### 5.4 timingle 이벤트를 Google Calendar에 동기화

**POST /api/v1/calendar/sync/:event_id**

timingle 이벤트를 Google Calendar에 추가/업데이트합니다.

Response:
```json
{
  "message": "event synced to Google Calendar",
  "calendar_event": {
    "id": "abc123xyz",
    "summary": "점심 약속",
    "start_time": "2024-01-15T12:00:00+09:00",
    "end_time": "2024-01-15T13:00:00+09:00",
    "html_link": "https://calendar.google.com/event?eid=xxx"
  }
}
```

## 6. Flutter 연동

### 6.1 google_sign_in에 Calendar Scope 추가

```dart
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
    'https://www.googleapis.com/auth/calendar',
  ],
);
```

### 6.2 Calendar 권한 로그인

```dart
Future<AuthResponse?> loginWithCalendar() async {
  final GoogleSignInAccount? account = await _googleSignIn.signIn();
  if (account == null) return null;

  final GoogleSignInAuthentication auth = await account.authentication;

  // Backend에 토큰 전송
  final response = await dio.post('/auth/google/calendar', data: {
    'id_token': auth.idToken,
    'access_token': auth.accessToken,
    // refresh_token은 첫 로그인 시에만 반환됨
  });

  return AuthResponse.fromJson(response.data);
}
```

### 6.3 권한 재요청 (기존 사용자)

```dart
Future<void> requestCalendarPermission() async {
  // 추가 scope 요청
  final bool granted = await _googleSignIn.requestScopes([
    'https://www.googleapis.com/auth/calendar',
  ]);

  if (granted) {
    // 새 토큰으로 다시 로그인
    await loginWithCalendar();
  }
}
```

## 7. 테스트

### 7.1 Postman 테스트

#### Calendar Scope로 토큰 획득

1. [OAuth Playground](https://developers.google.com/oauthplayground) 접속
2. 톱니바퀴 → "Use your own OAuth credentials" 체크
3. Client ID/Secret 입력
4. Step 1에서 scope 선택:
   - `openid`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`
   - `https://www.googleapis.com/auth/calendar`
5. "Authorize APIs" → Google 계정 로그인
6. "Exchange authorization code for tokens"
7. `id_token`, `access_token`, `refresh_token` 복사

#### API 테스트

```bash
# 1. Calendar 권한 로그인
curl -X POST http://localhost:8080/api/v1/auth/google/calendar \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "<ID_TOKEN>",
    "access_token": "<ACCESS_TOKEN>",
    "refresh_token": "<REFRESH_TOKEN>",
    "platform": "web"
  }'

# 2. Calendar 상태 확인 (JWT 토큰 필요)
curl http://localhost:8080/api/v1/calendar/status \
  -H "Authorization: Bearer <JWT_ACCESS_TOKEN>"

# 3. Calendar 이벤트 조회
curl "http://localhost:8080/api/v1/calendar/events?start_time=2024-01-01T00:00:00Z&end_time=2024-01-31T23:59:59Z" \
  -H "Authorization: Bearer <JWT_ACCESS_TOKEN>"

# 4. 이벤트 동기화
curl -X POST http://localhost:8080/api/v1/calendar/sync/1 \
  -H "Authorization: Bearer <JWT_ACCESS_TOKEN>"
```

## 8. 아키텍처

### 토큰 관리 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App                                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  google_sign_in SDK                                         │ │
│  │  - Scope: openid, email, profile, calendar                  │ │
│  │  - 반환: id_token, access_token                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Backend API                                                     │
│  POST /api/v1/auth/google/calendar                              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  1. id_token 검증 (기존 로직)                               │ │
│  │  2. access_token, refresh_token 저장                        │ │
│  │  3. JWT 토큰 발급                                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  oauth_accounts 테이블                                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  - access_token: Google API 호출용                          │ │
│  │  - refresh_token: 토큰 갱신용                               │ │
│  │  - token_expiry: 만료 시간                                  │ │
│  │  - scopes: 부여된 권한 목록                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Calendar Service                                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  토큰 만료 체크 → 자동 갱신 → Google Calendar API 호출     │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 자동 토큰 갱신

Calendar Service는 API 호출 전 자동으로 토큰 만료를 체크합니다:

1. `access_token` 만료 5분 전 체크
2. 만료 시 `refresh_token`으로 새 `access_token` 획득
3. DB에 갱신된 토큰 저장
4. API 호출 진행

## 9. 문제 해결

### "Calendar permission not granted" 오류
- Flutter에서 calendar scope를 요청했는지 확인
- Google OAuth 동의 화면에 calendar scope가 추가되었는지 확인
- 사용자가 권한을 승인했는지 확인

### "Failed to refresh token" 오류
- `GOOGLE_CLIENT_SECRET` 환경변수가 설정되었는지 확인
- refresh_token이 DB에 저장되어 있는지 확인
- Google Cloud Console에서 OAuth 자격증명이 유효한지 확인

### "Access token expired" 후 갱신 안됨
- refresh_token은 첫 로그인 시에만 반환됨
- 사용자가 권한을 취소 후 재승인하면 새 refresh_token 획득 가능

## 10. 보안 고려사항

- `access_token`과 `refresh_token`은 절대 클라이언트에 노출하지 않음
- JSON 응답에서 `json:"-"` 태그로 제외됨
- 토큰은 Backend에서만 관리하고 Calendar API 호출
- HTTPS 사용 필수 (프로덕션)

## 참고 링크

- [Google Calendar API 문서](https://developers.google.com/calendar/api/v3/reference)
- [OAuth 2.0 Scopes](https://developers.google.com/identity/protocols/oauth2/scopes#calendar)
- [google_sign_in Flutter 패키지](https://pub.dev/packages/google_sign_in)
- [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) - 기본 OAuth 설정
