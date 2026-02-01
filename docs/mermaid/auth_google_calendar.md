# Google Calendar 권한 포함 로그인

Calendar API 접근 권한을 포함한 Google OAuth 로그인 흐름입니다.

## 엔드포인트
- `POST /api/v1/auth/google/calendar`

## 기본 로그인과의 차이점

| 항목 | /auth/google | /auth/google/calendar |
|-----|--------------|----------------------|
| id_token | ✅ 필수 | ✅ 필수 |
| access_token | ❌ 없음 | ✅ 필수 |
| refresh_token | ❌ 없음 | ✅ 필수 |
| Calendar API | ❌ 사용 불가 | ✅ 사용 가능 |

## 시퀀스 다이어그램

```mermaid
sequenceDiagram
    autonumber
    participant U as 👤 사용자
    participant F as 📱 Flutter
    participant G as 🔵 Google
    participant B as 🖥️ Backend
    participant DB as 🗄️ PostgreSQL
    participant GC as 📅 Calendar API

    Note over U,GC: Google Calendar 권한 포함 로그인

    U->>F: Google 로그인 버튼 클릭
    F->>G: GoogleSignIn(scopes: [calendar])
    Note right of F: Calendar 권한 요청
    G->>U: 로그인 + Calendar 권한 요청 화면
    U->>G: 계정 선택 & 권한 승인
    G->>F: id_token + access_token + refresh_token

    rect rgb(255, 248, 240)
        Note over F,DB: Backend API 호출
        F->>B: POST /auth/google/calendar
        Note right of F: { id_token, access_token,<br/>refresh_token, platform }

        B->>G: id_token 검증
        G->>B: { email, name, sub }

        B->>DB: 사용자 조회/생성
        DB->>B: User

        B->>DB: oauth_accounts 저장
        Note right of DB: ✅ email, name, picture<br/>✅ access_token<br/>✅ refresh_token<br/>✅ scopes: [calendar]

        B->>B: JWT 토큰 생성
        B->>F: { access_token, refresh_token, user }
    end

    F->>F: TokenStorage에 저장
    F->>U: 로그인 완료

    Note over U,GC: 이후 Calendar API 사용 가능

    rect rgb(240, 255, 240)
        Note over F,GC: Calendar 기능 사용
        U->>F: 캘린더 이벤트 조회
        F->>B: GET /calendar/events
        B->>DB: oauth_accounts에서 google_access_token 조회
        DB->>B: google_access_token
        B->>GC: Calendar API 호출
        GC->>B: 캘린더 이벤트 목록
        B->>F: 이벤트 반환
        F->>U: 캘린더 표시
    end
```

## 요청/응답 예시

### Request
```json
POST /api/v1/auth/google/calendar
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "access_token": "ya29.a0AfH6SMB...",
  "refresh_token": "1//0eXyz...",
  "platform": "android"
}
```

### Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "abc123...",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "email": "user@gmail.com",
    "name": "홍길동"
  }
}
```

## 토큰 저장 구조

```mermaid
flowchart LR
    subgraph Google["🔵 Google 토큰"]
        GIT[google_id_token]
        GAT[google_access_token]
        GRT[google_refresh_token]
    end

    subgraph Backend["🖥️ Backend"]
        V[id_token 검증]
        S[oauth_accounts 저장]
        J[JWT 생성]
    end

    subgraph Client["📱 Client"]
        AT[access_token]
        RT[refresh_token]
    end

    GIT --> V
    V --> S
    GAT --> S
    GRT --> S
    S --> J
    J --> AT
    J --> RT
```

## 관련 파일
- Flutter: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Backend: `internal/handlers/auth_handler.go` → `GoogleCalendarLogin()`
- Backend: `internal/services/auth_service.go` → `GoogleLoginWithCalendar()`
