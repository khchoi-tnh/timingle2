# 테스트 순서 가이드

## ✅ 테스트 체크리스트

### 🚀 1단계: 서버 확인

- [ ] **1-1. Health Check** - 서버 상태 확인
  - URL: `http://localhost:8080/health` (⚠️ `/api/v1` prefix 없음)
  - 예상 응답: `{"status": "healthy", "service": "timingle-api"}`

---

### 🔐 2단계: 인증

- [ ] **2-1. Register** - 회원가입
  - 새 계정 생성
  - 이미 존재하면 스킵

- [ ] **2-1. Login** - 로그인
  - ✅ `access_token` 자동 저장됨
  - ✅ `refresh_token` 자동 저장됨

- [ ] **2-2. Refresh Token** (선택)
  - Access Token 갱신 테스트

- [ ] **2-3. Google Login** (선택)
  - ⚠️ Flutter 앱에서 발급한 토큰 필요

---

### 👤 3단계: 사용자

- [ ] **3-1. Get My Profile** - 내 정보 조회
  - URL: `{{base_url}}/auth/me` (⚠️ `/users/me` 아님)
  - ✅ `user_id` 자동 저장됨

---

### 📅 4단계: 이벤트

#### 4-1. CRUD

- [ ] **Create Event** - 이벤트 생성
  - ✅ `event_id` 자동 저장됨

- [ ] **Get Events** - 목록 조회
  - 필터: status, limit

- [ ] **Get Event by ID** - 상세 조회

- [ ] **Update Event** - 수정
  - PATCH로 부분 수정

- [ ] **Delete Event** - 삭제 (마지막에)

#### 4-2. Status

- [ ] **Confirm Event** - 이벤트 확정
  - PROPOSED → CONFIRMED

- [ ] **Cancel Event** - 이벤트 취소
  - → CANCELED

#### 4-3. Messages

- [ ] **Get Messages** - 메시지 조회

- [ ] **Send Message** - 메시지 전송

#### 4-4. Invites (초대)

- [ ] **Create Invite Link** - 초대 링크 생성
  - ✅ `invite_code` 자동 저장됨
  - 생성된 링크를 카카오톡, 문자 등으로 공유

- [ ] **Get Invite Info** - 초대 정보 조회
  - 다른 계정으로 로그인 후 테스트

- [ ] **Join via Invite** - 초대 링크로 참가

- [ ] **Accept Invite** - 초대 수락

- [ ] **Decline Invite** - 초대 거절

---

### 📆 5단계: Calendar (Google OAuth 필요)

⚠️ **사전 조건**: Google Calendar 권한으로 로그인

- [ ] **5-1. Get Calendar Status** - 연동 상태

- [ ] **5-2. Get Calendar Events** - 캘린더 이벤트

- [ ] **5-3. Sync Event** - 이벤트 동기화

---

### 🚧 6단계: 미구현 (테스트 불가)

- ❌ 6-1. Friends - Backend 미구현
- ❌ 6-2. Open Slots - Backend 미구현
- ❌ 6-3. Payments - Backend 미구현

---

## 📊 테스트 결과 확인

### Postman Console

`View` → `Show Postman Console` 에서 요청/응답 확인

### Test Results

각 요청 후 `Test Results` 탭에서 테스트 통과 여부 확인

```
✓ Status 200
✓ Has status field
```

---

## 🔁 권장 테스트 순서

```
1_health.json
    └─ 1-1. Health Check

2_auth.json
    └─ 2-1. Phone Auth
        ├─ Register
        └─ Login ← access_token 저장

3_users.json
    └─ 3-1. Get My Profile

4_events.json
    └─ 4-1. CRUD
        ├─ Create Event ← event_id 저장
        ├─ Get Events
        ├─ Get Event by ID
        └─ Update Event
    └─ 4-2. Status
        ├─ Confirm Event
        └─ Cancel Event
    └─ 4-3. Messages
        ├─ Get Messages
        └─ Send Message
    └─ 4-4. Invites
        ├─ Create Invite Link ← invite_code 저장
        ├─ Get Invite Info (다른 계정으로)
        ├─ Join via Invite
        ├─ Accept Invite
        └─ Decline Invite

5_calendar.json (Google OAuth 필요)
    ├─ 5-1. Get Calendar Status
    ├─ 5-2. Get Calendar Events
    └─ 5-3. Sync Event
```
