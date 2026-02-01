# OAuth Playground로 토큰 발급

Postman에서 Google OAuth API를 테스트하기 위해 OAuth Playground에서 토큰을 발급받는 흐름입니다.

## OAuth Playground URL
- https://developers.google.com/oauthplayground

## 시퀀스 다이어그램

```mermaid
sequenceDiagram
    autonumber
    participant D as 👤 개발자
    participant OP as 🔧 OAuth Playground
    participant G as 🔵 Google
    participant PM as 📮 Postman
    participant B as 🖥️ Backend

    Note over D,B: OAuth Playground로 토큰 발급 후 Postman 테스트

    D->>OP: 1. 접속
    Note right of D: developers.google.com<br/>/oauthplayground

    D->>OP: 2. 설정 (⚙️)
    Note right of D: ☑️ Use your own OAuth credentials<br/>Client ID / Secret 입력

    D->>OP: 3. Scope 선택
    Note right of D: ✅ openid<br/>✅ email<br/>✅ profile<br/>✅ calendar (선택)

    D->>OP: 4. Authorize APIs 클릭
    OP->>G: OAuth 요청
    G->>D: 로그인 화면 표시
    D->>G: 계정 선택 & 권한 승인
    G->>OP: Authorization Code

    D->>OP: 5. Exchange 클릭
    OP->>G: Authorization Code → Token 교환
    G->>OP: 토큰 발급

    OP->>D: 6. 토큰 표시
    Note left of OP: {<br/>  "id_token": "eyJ...",<br/>  "access_token": "ya29...",<br/>  "refresh_token": "1//..."<br/>}

    rect rgb(240, 255, 240)
        Note over D,B: Postman에서 테스트
        D->>PM: 7. 환경변수 설정
        Note right of D: google_id_token<br/>google_access_token<br/>google_refresh_token

        PM->>B: 8. POST /auth/google/calendar
        B->>G: id_token 검증
        G->>B: 사용자 정보
        B->>PM: { access_token (JWT), user }

        PM->>D: 9. 테스트 성공
    end
```

## Step-by-Step 가이드

### Step 1: OAuth Playground 접속
```
https://developers.google.com/oauthplayground
```

### Step 2: 설정 (우측 상단 ⚙️)
```
☑️ Use your own OAuth credentials

OAuth Client ID: [backend/.env의 GOOGLE_CLIENT_ID]
OAuth Client secret: [backend/.env의 GOOGLE_CLIENT_SECRET]
```

### Step 3: Scope 선택 (왼쪽 패널)

```mermaid
flowchart TD
    subgraph Scopes["Step 1: Select & authorize APIs"]
        subgraph OAuth2["Google OAuth2 API v2"]
            S1[userinfo.email]
            S2[userinfo.profile]
            S3[openid]
        end
        subgraph Calendar["Google Calendar API v3"]
            S4[calendar]
        end
    end

    OAuth2 --> |기본 로그인| Basic["/auth/google"]
    OAuth2 --> |Calendar 로그인| Cal["/auth/google/calendar"]
    Calendar --> Cal
```

### Step 4: Authorize APIs 클릭
- Google 로그인 화면 표시
- 계정 선택 및 권한 승인

### Step 5: Exchange authorization code for tokens 클릭
```json
{
  "access_token": "ya29.a0AfH6SMB...",
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "refresh_token": "1//0eXyz...",
  "expires_in": 3599,
  "token_type": "Bearer"
}
```

### Step 6: Postman 환경변수 설정
| 변수명 | 값 |
|-------|-----|
| `google_id_token` | eyJhbGciOiJSUzI1NiIs... |
| `google_access_token` | ya29.a0AfH6SMB... |
| `google_refresh_token` | 1//0eXyz... |

### Step 7: Postman에서 테스트
- `2_auth.json` → `2-3. Google OAuth` → 요청 실행

## OAuth Playground vs Flutter 비교

```mermaid
flowchart LR
    subgraph Playground["🔧 OAuth Playground"]
        P1[✅ 앱 없이 테스트]
        P2[✅ 모든 scope 선택]
        P3[✅ refresh_token 항상 발급]
        P4[⚠️ 수동 토큰 복사]
    end

    subgraph Flutter["📱 Flutter 앱"]
        F1[❌ 앱 빌드 필요]
        F2[⚠️ 앱 scope만]
        F3[⚠️ 첫 로그인만 refresh]
        F4[✅ 자동 갱신]
    end

    Playground --> |개발 초기| Dev[개발/테스트]
    Flutter --> |프로덕션| Prod[실제 사용]
```

## 주의사항

1. **Client ID/Secret**: `backend/.env`의 값과 동일해야 함
2. **토큰 만료**: access_token은 1시간 후 만료, refresh_token으로 갱신 가능
3. **Scope 일치**: Backend에서 기대하는 scope와 일치해야 함
