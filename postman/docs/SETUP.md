# 환경 설정 가이드

## 1️⃣ Backend 실행

### WSL (AlmaLinux)에서 실행

```bash
# 1. WSL 접속
wsl -d AlmaLinux-Kitten-10

# 2. 컨테이너 시작
bash /mnt/d/projects/timingle2/containers/setup_podman.sh

# 3. Backend 실행
bash /mnt/d/projects/timingle2/backend/run.sh
```

### 서비스 상태 확인

```bash
# 컨테이너 상태
podman ps

# Backend 로그
tail -f /mnt/d/projects/timingle2/backend/server.log
```

## 2️⃣ Postman 설정

### Import 순서

1. **Environment 먼저**: `timingle-local.postman_environment.json`
2. **Collection 순서대로**:
   - `1_health.json`
   - `2_auth.json`
   - `3_users.json`
   - `4_events.json`
   - `5_calendar.json`
   - `6_future.json` (선택)

### base_url 설정

#### 방법 1: Environment 파일 Import (권장)

```
Postman → Import → 파일 선택
→ postman/timingle-local.postman_environment.json

우측 상단 드롭다운 → "timingle-local" 선택
```

#### 방법 2: 수동 설정

```
1. 우측 상단 ⚙️ (Environments) 클릭
2. "+" 버튼으로 새 환경 생성
3. 이름: timingle-local
4. 변수 추가:

   Variable     Type      Initial Value
   ──────────────────────────────────────────────────────
   base_url     default   http://localhost:8080/api/v1
```

#### 환경별 base_url

| 환경 | base_url |
|-----|----------|
| **Local (WSL)** | `http://localhost:8080/api/v1` |
| **Local (Windows 직접)** | `http://127.0.0.1:8080/api/v1` |
| **Production** | `https://api.timingle.com/api/v1` (예정) |

#### 확인 방법

```
👁️ (눈 아이콘) 클릭 → 환경변수 목록 확인

base_url: http://localhost:8080/api/v1 ✅
```

### Environment 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `base_url` | `http://localhost:8080/api/v1` | API 주소 |
| `access_token` | (자동) | JWT Access Token |
| `refresh_token` | (자동) | JWT Refresh Token |
| `user_id` | (자동) | 로그인한 사용자 ID |
| `event_id` | (자동) | 생성한 이벤트 ID |
| `google_id_token` | (수동) | Google ID Token |
| `google_access_token` | (수동) | Google OAuth Token |
| `google_refresh_token` | (수동) | Google Refresh Token |

### 자동 토큰 저장

로그인 성공 시 `access_token`과 `refresh_token`이 자동으로 Environment에 저장됩니다.

```javascript
// 2_auth.json의 Login 요청에 포함된 Test Script
if (pm.response.code === 200) {
    var json = pm.response.json();
    if (json.access_token) pm.environment.set("access_token", json.access_token);
    if (json.refresh_token) pm.environment.set("refresh_token", json.refresh_token);
}
```

## 3️⃣ 문제 해결

### Backend 연결 실패

```
Error: connect ECONNREFUSED 127.0.0.1:8080
```

**해결**: WSL에서 Backend가 실행 중인지 확인

```bash
# ⚠️ Health Check는 /api/v1 prefix 없이 루트에 있습니다
wsl -d AlmaLinux-Kitten-10 -e bash -c "curl http://localhost:8080/health"

# 예상 응답:
# {"service":"timingle-api","status":"healthy"}
```

### Health Check 404 오류

```
404 page not found
```

**원인**: `/api/v1/health` 대신 `/health`로 요청해야 함

**해결**:
- ✅ `http://localhost:8080/health`
- ❌ `http://localhost:8080/api/v1/health`

> Health Check 엔드포인트만 루트 경로에 있고, 나머지 API는 모두 `/api/v1` prefix를 사용합니다.

### 인증 실패

```
{"error": "unauthorized"}
```

**해결**:
1. `2_auth.json` → Login 먼저 실행
2. Environment에서 `access_token` 값 확인

### Google OAuth 테스트

#### 방법 1: OAuth Playground (권장)

앱 없이 브라우저에서 토큰 발급:

```
1. https://developers.google.com/oauthplayground 접속
2. 우측 상단 ⚙️ → "Use your own OAuth credentials" 체크
3. Client ID/Secret 입력 (backend/.env에서 복사)
4. Scope 선택:
   - openid, email, profile
   - https://www.googleapis.com/auth/calendar (Calendar 연동 시)
5. Authorize APIs → 로그인
6. Exchange authorization code for tokens
7. 토큰 복사 → Environment 변수에 붙여넣기
```

📖 자세한 가이드: [GOOGLE_AUTH_FLOW.md](GOOGLE_AUTH_FLOW.md)

#### 방법 2: Flutter 앱

```
1. Flutter 앱에서 Google 로그인 실행
2. 콘솔에서 토큰 복사
3. Environment 변수에 붙여넣기
```

#### Environment 변수 설정

```
google_id_token: eyJhbGciOiJSUzI1NiIs...
google_access_token: ya29.a0AfH6SMB...
google_refresh_token: 1//0eXyz...
```
