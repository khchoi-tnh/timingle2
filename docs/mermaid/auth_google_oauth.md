# Google OAuth 기본 로그인

Flutter 앱에서 Google OAuth로 로그인하는 전체 흐름입니다.

## 엔드포인트
- `POST /api/v1/auth/google`

## 시퀀스 다이어그램

```mermaid
sequenceDiagram
    autonumber
    participant U as 👤 사용자
    participant F as 📱 Flutter
    participant G as 🔵 Google
    participant B as 🖥️ Backend
    participant DB as 🗄️ PostgreSQL

    Note over U,DB: Google OAuth 기본 로그인 (/auth/google)

    U->>F: Google 로그인 버튼 클릭
    F->>G: GoogleSignIn.signIn()
    G->>U: 로그인 화면 표시
    U->>G: 계정 선택 & 로그인
    G->>F: GoogleSignInAccount 반환
    F->>G: googleUser.authentication
    G->>F: id_token 반환

    rect rgb(240, 248, 255)
        Note over F,DB: Backend API 호출
        F->>B: POST /auth/google
        Note right of F: { id_token, platform }

        B->>G: id_token 검증
        G->>B: { email, name, sub }

        B->>DB: 사용자 조회/생성
        DB->>B: User

        B->>DB: oauth_accounts 저장
        Note right of DB: email, name, picture만<br/>❌ access_token 없음

        B->>B: JWT 토큰 생성
        B->>F: { access_token, refresh_token, user }
    end

    F->>F: TokenStorage에 저장
    F->>U: 로그인 완료
```

## 요청/응답 예시

### Request
```json
POST /api/v1/auth/google
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
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

## 관련 파일
- Flutter: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Backend: `internal/handlers/auth_handler.go` → `GoogleLogin()`
- Backend: `internal/services/auth_service.go` → `GoogleLogin()`
